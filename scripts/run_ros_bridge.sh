#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/humble/setup.bash

echo "Bridging X3 LiDAR and camera to ROS 2..."
ros2 run ros_gz_bridge parameter_bridge \
    /model/X3/lidar/scan@sensor_msgs/msg/LaserScan[gz.msgs.LaserScan \
    /model/X3/camera/image@sensor_msgs/msg/Image[gz.msgs.Image \
    /model/X3/camera/camera_info@sensor_msgs/msg/CameraInfo[gz.msgs.CameraInfo
