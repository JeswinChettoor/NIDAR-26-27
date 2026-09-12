#!/usr/bin/env python3
import math
import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy
from sensor_msgs.msg import LaserScan, Range


class RangefinderToMavrosBridge(Node):
    """
    Converts a LaserScan-style rangefinder (e.g. a Gazebo downward-facing
    sensor publishing as LaserScan) into a single sensor_msgs/Range reading,
    on the topic mavros's distance_sensor plugin subscribes to.
    """

    def __init__(self):
        super().__init__('rangefinder_to_mavros_bridge')

        self.declare_parameter('input_topic', '/rangefinder')
        # Must match the ROS subscriber name mavros expects, e.g. the key
        # you gave the distance_sensor plugin in apm_config.yaml
        self.declare_parameter('output_topic', '/mavros/distance_sensor/rangefinder_sub')
        self.declare_parameter('frame_id', 'rangefinder_link')
        # If left at 0.0, min/max/fov are taken from the incoming LaserScan itself.
        self.declare_parameter('min_range_override', 0.0)
        self.declare_parameter('max_range_override', 0.0)
        self.declare_parameter('field_of_view_override', 0.0)

        input_topic = self.get_parameter('input_topic').value
        output_topic = self.get_parameter('output_topic').value
        self.frame_id = self.get_parameter('frame_id').value
        self.min_range_override = self.get_parameter('min_range_override').value
        self.max_range_override = self.get_parameter('max_range_override').value
        self.fov_override = self.get_parameter('field_of_view_override').value

        qos = QoSProfile(
            reliability=ReliabilityPolicy.RELIABLE,
            history=HistoryPolicy.KEEP_LAST,
            depth=10,
        )

        self.pub = self.create_publisher(Range, output_topic, qos)
        self.sub = self.create_subscription(LaserScan, input_topic, self.cb, qos)
        self.get_logger().info(f'Bridging {input_topic} (LaserScan) -> {output_topic} (Range)')

    def cb(self, msg: LaserScan):
        range_min = self.min_range_override or msg.range_min
        range_max = self.max_range_override or msg.range_max

        valid = [
            r for r in msg.ranges
            if math.isfinite(r) and range_min <= r <= range_max
        ]

        if not valid:
            # No valid return this cycle — skip rather than fabricate a
            # distance ArduPilot would treat as a real measurement.
            self.get_logger().debug('No valid range in scan, skipping publish')
            return

        closest = min(valid)

        # 1. Strictly sanitize the FOV to prevent NaN truthiness bugs
        computed_fov = abs(msg.angle_max - msg.angle_min)
        
        if self.fov_override > 0.0:
            fov = self.fov_override
        elif not math.isnan(computed_fov) and computed_fov > 0.0:
            fov = computed_fov
        elif not math.isnan(msg.angle_increment) and msg.angle_increment > 0.0:
            fov = msg.angle_increment
        else:
            # Fallback to a valid float if Gazebo sends NaNs or zeros
            fov = 0.1  

        out = Range()
        out.header = msg.header
        out.header.frame_id = self.frame_id
        out.radiation_type = Range.INFRARED  # change to Range.ULTRASOUND if applicable
        out.field_of_view = float(fov)       # Assign the sanitized float
        out.min_range = float(range_min)
        out.max_range = float(range_max)
        out.range = float(closest)
        self.pub.publish(out)


def main():
    rclpy.init()
    node = RangefinderToMavrosBridge()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
