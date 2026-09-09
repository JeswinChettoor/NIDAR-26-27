import rclpy
from rclpy.node import Node
from sensor_msgs.msg import LaserScan, PointCloud2
from laser_geometry import LaserProjection

class ScanToCloud(Node):
    def __init__(self):
        super().__init__('scan_to_cloud')
        self.projector = LaserProjection()
        # Publish the raw 3D cloud
        self.pub = self.create_publisher(PointCloud2, '/scan_cloud_raw', 10)
        # Subscribe to the raw 2D scan
        self.create_subscription(LaserScan, '/scan', self.cb, 10)

    def cb(self, scan: LaserScan):
        # Project 2D scan to 3D point cloud. 
        # The frame_id remains 'laser_link'
        cloud = self.projector.projectLaser(scan)
        self.pub.publish(cloud)

def main():
    rclpy.init()
    node = ScanToCloud()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
