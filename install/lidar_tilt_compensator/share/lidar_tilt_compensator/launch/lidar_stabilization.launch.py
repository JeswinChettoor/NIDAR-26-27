import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    # Dynamically find the config file inside the installed package
    config_dir = os.path.join(get_package_share_directory('lidar_tilt_compensator'), 'config')
    scan_stabilizer_params = os.path.join(config_dir, 'scan_stabilizer.yaml')

    return LaunchDescription([
        # 1. Static TF: base_link -> LiDAR frame (matching Gazebo)
        Node(
            package='tf2_ros',
            executable='static_transform_publisher',
            name='static_tf_base_to_lidar',
            arguments=['0.20', '0.0', '0.10', '0', '0', '0', 'base_link', 'iris/lidar_link/lidar_2d'],
            parameters=[{'use_sim_time': True}]
        ),
        
        # 2. FCU TF Bridge: base_footprint -> base_link
        Node(
            package='fcu_tf_bridge',
            executable='fcu_tf_bridge_node',
            name='fcu_tf_bridge',
            parameters=[{'use_sim_time': True}]
        ),
        
        # 3. Scan to Cloud: 2D -> 3D conversion
        Node(
            package='lidar_tilt_compensator',
            executable='scan_to_cloud_node',
            name='scan_to_cloud',
            parameters=[{'use_sim_time': True}]
        ),
        
        # 4. Pointcloud to Laserscan: 3D -> Stabilized 2D
        Node(
            package='pointcloud_to_laserscan',
            executable='pointcloud_to_laserscan_node',
            name='pointcloud_to_laserscan',
            remappings=[
                ('cloud_in', '/scan_cloud_raw'),
                ('scan', '/scan_stabilized')
            ],
            parameters=[
                scan_stabilizer_params,  # Load the YAML file
                {'use_sim_time': True}   # Force sim time
            ]
        )
    ])
