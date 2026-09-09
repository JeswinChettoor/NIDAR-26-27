import math
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Imu
from geometry_msgs.msg import PoseStamped
from tf2_ros import TransformBroadcaster
from geometry_msgs.msg import TransformStamped
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy

def quat_to_roll_pitch(x, y, z, w):
    # standard ZYX Euler extraction, ROS convention
    sinr_cosp = 2 * (w * x + y * z)
    cosr_cosp = 1 - 2 * (x * x + y * y)
    roll = math.atan2(sinr_cosp, cosr_cosp)

    sinp = 2 * (w * y - z * x)
    sinp = max(-1.0, min(1.0, sinp))
    pitch = math.asin(sinp)
    return roll, pitch


def rpy_to_quat(roll, pitch, yaw):
    cy, sy = math.cos(yaw * 0.5), math.sin(yaw * 0.5)
    cp, sp = math.cos(pitch * 0.5), math.sin(pitch * 0.5)
    cr, sr = math.cos(roll * 0.5), math.sin(roll * 0.5)
    return (
        sr * cp * cy - cr * sp * sy,
        cr * sp * cy + sr * cp * sy,
        cr * cp * sy - sr * sp * cy,
        cr * cp * cy + sr * sp * sy,
    )


class FcuTfBridge(Node):
    def __init__(self):
        super().__init__('fcu_tf_bridge')
        self.br = TransformBroadcaster(self)
        self.latest_z = 0.0

        # Define Best Effort QoS to match MAVROS publishers
        qos_profile = QoSProfile(
            reliability=ReliabilityPolicy.BEST_EFFORT,
            history=HistoryPolicy.KEEP_LAST,
            depth=10
        )

        self.create_subscription(Imu, '/mavros/imu/data', self.imu_cb, qos_profile)
        self.create_subscription(PoseStamped, '/mavros/local_position/pose',
                                  self.pose_cb, qos_profile)
    def pose_cb(self, msg: PoseStamped):
        # local EKF altitude, used as base_link height above base_footprint
        self.latest_z = msg.pose.position.z

    def imu_cb(self, msg: Imu):
        q = msg.orientation
        roll, pitch = quat_to_roll_pitch(q.x, q.y, q.z, q.w)

        # yaw intentionally omitted -- SLAM/RF2O owns yaw via odom->base_footprint
        qx, qy, qz, qw = rpy_to_quat(roll, pitch, 0.0)

        t = TransformStamped()
        t.header.stamp = self.get_clock().now().to_msg()# keep FCU timestamp for correct TF interpolation
        t.header.frame_id = 'base_footprint'
        t.child_frame_id = 'base_link'
        t.transform.translation.x = 0.0
        t.transform.translation.y = 0.0
        t.transform.translation.z = self.latest_z
        t.transform.rotation.x = qx
        t.transform.rotation.y = qy
        t.transform.rotation.z = qz
        t.transform.rotation.w = qw
        self.br.sendTransform(t)


def main():
    rclpy.init()
    node = FcuTfBridge()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
