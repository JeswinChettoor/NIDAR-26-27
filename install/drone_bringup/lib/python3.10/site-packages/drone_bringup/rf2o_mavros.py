#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy
from nav_msgs.msg import Odometry

# Indices into the 6-length diagonal: [x, y, z, roll, pitch, yaw]
UNOBSERVED_2D_INDICES = (2, 3, 4)  # z, roll, pitch — rf2o cannot measure these
LARGE_VARIANCE = 1e6


class Rf2oToMavrosBridge(Node):
    def __init__(self):
        super().__init__('rf2o_to_mavros_bridge')

        self.declare_parameter('input_topic', '/rf2o_odom')
        self.declare_parameter('output_topic', '/mavros/odometry/out')
        self.declare_parameter('frame_id', 'odom')
        self.declare_parameter('child_frame_id', 'base_link')
        # x, y, z, roll, pitch, yaw — z/roll/pitch default high since rf2o is 2D-only
        self.declare_parameter(
            'pose_covariance_diag',
            [0.01, 0.01, LARGE_VARIANCE, LARGE_VARIANCE, LARGE_VARIANCE, 0.05],
        )
        self.declare_parameter(
            'twist_covariance_diag',
            [0.01, 0.01, LARGE_VARIANCE, LARGE_VARIANCE, LARGE_VARIANCE, 0.05],
        )

        input_topic = self.get_parameter('input_topic').value
        output_topic = self.get_parameter('output_topic').value
        self.frame_id = self.get_parameter('frame_id').value
        self.child_frame_id = self.get_parameter('child_frame_id').value
        self.pose_cov_diag = self._validate_diag(
            self.get_parameter('pose_covariance_diag').value, 'pose_covariance_diag'
        )
        self.twist_cov_diag = self._validate_diag(
            self.get_parameter('twist_covariance_diag').value, 'twist_covariance_diag'
        )

        # mavros's odometry subscriber requests RELIABLE — match it, or
        # messages get silently dropped (no error, just no delivery).
        qos = QoSProfile(
            reliability=ReliabilityPolicy.RELIABLE,
            history=HistoryPolicy.KEEP_LAST,
            depth=10,
        )

        self.pub = self.create_publisher(Odometry, output_topic, qos)
        self.sub = self.create_subscription(Odometry, input_topic, self.cb, qos)
        self.get_logger().info(f'Bridging {input_topic} -> {output_topic}')

    def _validate_diag(self, diag, name):
        if len(diag) != 6:
            self.get_logger().error(
                f"Parameter '{name}' must have exactly 6 values (x,y,z,roll,pitch,yaw), "
                f'got {len(diag)}: {diag}. Falling back to defaults.'
            )
            return [0.01, 0.01, LARGE_VARIANCE, LARGE_VARIANCE, LARGE_VARIANCE, 0.05]
        return [float(v) for v in diag]

    def cb(self, msg: Odometry):
        out = Odometry()
        out.header = msg.header
        out.header.frame_id = self.frame_id
        out.child_frame_id = self.child_frame_id
        out.pose.pose = msg.pose.pose
        out.twist.twist = msg.twist.twist

        out.pose.covariance = self._resolve_covariance(
            msg.pose.covariance, self.pose_cov_diag
        )
        out.twist.covariance = self._resolve_covariance(
            msg.twist.covariance, self.twist_cov_diag
        )
        self.pub.publish(out)

    def _resolve_covariance(self, incoming, fallback_diag):
        # Use the incoming covariance if it looks populated, but always force
        # the unobserved 2D axes (z, roll, pitch) to a large variance —
        # rf2o cannot measure them, so never trust zeros or small values there.
        if all(v == 0.0 for v in incoming):
            cov = self._diag_to_cov(fallback_diag)
        else:
            cov = list(incoming)
            for i in UNOBSERVED_2D_INDICES:
                diag_idx = i * 6 + i
                if cov[diag_idx] < LARGE_VARIANCE:
                    cov[diag_idx] = LARGE_VARIANCE
        return cov

    @staticmethod
    def _diag_to_cov(diag):
        cov = [0.0] * 36
        for i, v in enumerate(diag):
            cov[i * 6 + i] = v
        return cov


def main():
    rclpy.init()
    node = Rf2oToMavrosBridge()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
