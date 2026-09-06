from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from ament_index_python.packages import get_package_share_directory
import os


def generate_launch_description():
    # Path to rf2o launch file
    rf2o_pkg = get_package_share_directory('rf2o_laser_odometry')
    rf2o_launch = os.path.join(rf2o_pkg, 'launch', 'rf2o_laser_odometry.launch.py')

    return LaunchDescription([

        # === STATIC TFs ===
        # base_link -> laser (your LiDAR mount position - ADJUST THESE VALUES)
        Node(
            package='tf2_ros',
            executable='static_transform_publisher',
            arguments=['0', '0', '0.1', '0', '0', '0', 'base_link', 'laser']
        ),

        # base_link -> base_stabilized (gravity-aligned virtual frame)
        Node(
            package='tf2_ros',
            executable='static_transform_publisher',
            arguments=['0', '0', '0', '0', '0', '0', 'base_link', 'base_stabilized']
        ),

        # === SCAN PREPROCESSOR ===
        # Derolls/depitches scan using IMU, gates on excessive tilt
        Node(
            package='lidar_preprocessing',
            executable='scan_preprocessor',
            name='scan_preprocessor',
            output='screen',
            parameters=[{
                'max_tilt_deg': 20.0,
                'height_gate_m': 0.20,
                'min_range_m': 0.15,
                'max_range_m': 10.0,
            }]
        ),

        # === RF2O LASER ODOMETRY ===
        # Include your existing launch but override the scan topic
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(rf2o_launch),
            launch_arguments={
                'use_sim_time': 'true',
            }.items()
        ),

        # === ODOM BRIDGE ===
        # Validates RF2O output and forwards velocity-only to MAVROS
        Node(
            package='lidar_preprocessing',
            executable='odom_bridge',
            name='odom_bridge',
            output='screen',
            parameters=[{
                'max_accel_xy': 5.0,
                'max_speed_xy': 10.0,
            }]
        ),

        # === SLAM TOOLBOX ===
        # Global mapping using stabilized scan + EKF3 odometry TF
        Node(
            package='slam_toolbox',
            executable='async_slam_toolbox_node',
            name='slam_toolbox',
            output='screen',
            parameters=[{
                'use_sim_time': True,
                'odom_frame': 'odom',
                'map_frame': 'map',
                'base_frame': 'base_link',
                'scan_topic': '/scan_stabilized',
                'mode': 'mapping',
                'resolution': 0.05,
                'max_laser_range': 10.0,
                'minimum_travel_distance': 0.5,
                'minimum_travel_heading': 0.5,
            }]
        ),
    ])
