from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    return LaunchDescription([

        Node(
            package='tf2_ros',
            executable='static_transform_publisher',
            arguments=['0', '0', '0.1', '0', '0', '0', 'base_link', 'laser']
        ),

        Node(
            package='tf2_ros',
            executable='static_transform_publisher',
            arguments=['0', '0', '0', '0', '0', '0', 'base_link', 'base_stabilized']
        ),

        Node(
            package='lidar_preprocessing',
            executable='scan_preprocessor',
            name='scan_preprocessor',
            output='screen'
        ),

        Node(
            package='rf2o_laser_odometry',
            executable='rf2o_laser_odometry_node',
            name='rf2o',
            output='screen',
            remappings=[('/scan', '/scan_stabilized')]
        ),

        Node(
            package='lidar_preprocessing',
            executable='odom_bridge',
            name='odom_bridge',
            output='screen'
        ),

        Node(
            package='slam_toolbox',
            executable='async_slam_toolbox_node',
            name='slam_toolbox',
            output='screen',
            parameters=[{
                'odom_frame': 'odom',
                'map_frame': 'map',
                'base_frame': 'base_link',
                'scan_topic': '/scan_stabilized',
                'mode': 'mapping',
                'resolution': 0.05,
            }]
        ),
    ])
