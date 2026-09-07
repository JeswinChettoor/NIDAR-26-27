import os
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch.launch_description_sources import AnyLaunchDescriptionSource
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare

def generate_launch_description():
    use_sim_time = LaunchConfiguration('use_sim_time')
    bridge_config = LaunchConfiguration('bridge_config')
    mavros_config = LaunchConfiguration('mavros_config')
    fcu_url = LaunchConfiguration('fcu_url')
    gcs_url = LaunchConfiguration('gcs_url')

    default_bridge_config_path = PathJoinSubstitution([
        FindPackageShare('drone_bringup'),
        'config',
        'bridge.yaml'
    ])

    default_mavros_config_path = PathJoinSubstitution([
        FindPackageShare('drone_bringup'),
        'config',
        'mavros_config.yaml'
    ])

    declare_use_sim_time = DeclareLaunchArgument(
        'use_sim_time',
        default_value='true',
        description='Sync all nodes to simulation clock (/clock)'
    )

    declare_bridge_config = DeclareLaunchArgument(
        'bridge_config',
        default_value=default_bridge_config_path,
        description='Path to ros_gz_bridge parameter YAML config'
    )

    declare_mavros_config = DeclareLaunchArgument(
        'mavros_config',
        default_value=default_mavros_config_path,
        description='Path to custom MAVROS config YAML (enables distance_sensor)'
    )

    declare_fcu_url = DeclareLaunchArgument(
        'fcu_url',
        default_value='udp://127.0.0.1:14550@127.0.0.1:14557',
        description='MAVLink FCU connection URL'
    )

    declare_gcs_url = DeclareLaunchArgument(
        'gcs_url',
        default_value='',
        description='Optional GCS passthrough URL'
    )

    # 1. Gazebo Bridge
    bridge_node = Node(
        package='ros_gz_bridge',
        executable='parameter_bridge',
        name='ros_gz_bridge',
        output='screen',
        parameters=[{
            'config_file': bridge_config,
            'use_sim_time': use_sim_time,
        }],
    )

    # 2. MAVROS (loads custom mavros_config.yaml for distance_sensor plugin)
    mavros_launch = IncludeLaunchDescription(
        AnyLaunchDescriptionSource(
            PathJoinSubstitution([
                FindPackageShare('mavros'),
                'launch',
                'apm.launch',
            ])
        ),
        launch_arguments={
            'fcu_url': fcu_url,
            'gcs_url': gcs_url,
            'use_sim_time': use_sim_time,
            'config_yaml': mavros_config,
        }.items(),
    )

    # 3. Scan Preprocessor
    scan_preprocessor_node = Node(
        package='lidar_preprocessing',
        executable='scan_preprocessor',
        name='scan_preprocessor',
        output='screen',
        parameters=[{
            'use_sim_time': use_sim_time,
            'max_tilt_deg': 20.0,
            'height_gate_m': 0.20,
            'min_range_m': 0.15,
            'max_range_m': 10.0
        }],
    )

    # 4. RF2O Laser Odometry
    rf2o_node = Node(
        package='rf2o_laser_odometry',
        executable='rf2o_laser_odometry_node',
        name='rf2o_laser_odometry',
        output='screen',
        parameters=[{
            'laser_scan_topic': '/scan_stabilized',
            'odom_topic': '/odom_rf2o',
            'publish_tf': False,
            'base_frame_id': 'base_stabilized',
            'odom_frame_id': 'odom',
            'init_pose_from_topic': '',
            'freq': 20.0,
            'use_sim_time': use_sim_time,
        }],
    )

    # 5. Odom Safety Bridge
    odom_bridge_node = Node(
        package='lidar_preprocessing',
        executable='odom_bridge',
        name='odom_bridge',
        output='screen',
        parameters=[{
            'use_sim_time': use_sim_time,
            'max_accel_xy': 5.0,
            'max_speed_xy': 10.0
        }],
    )

    # 6. Rangefinder LaserScan -> Range Converter Node
    rangefinder_converter_node = Node(
        package='drone_bringup',
        executable='rangefinder_converter',
        name='rangefinder_converter',
        output='screen',
        parameters=[{
            'use_sim_time': use_sim_time,
        }],
    )

    return LaunchDescription([
        declare_use_sim_time,
        declare_bridge_config,
        declare_mavros_config,
        declare_fcu_url,
        declare_gcs_url,
        bridge_node,
        mavros_launch,
        scan_preprocessor_node,
        rf2o_node,
        odom_bridge_node,
        rangefinder_converter_node,
    ])
