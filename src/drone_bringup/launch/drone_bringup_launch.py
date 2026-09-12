from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch.launch_description_sources import AnyLaunchDescriptionSource
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare

def generate_launch_description():
    use_sim_time = LaunchConfiguration('use_sim_time')
    bridge_config = LaunchConfiguration('bridge_config')
    fcu_url = LaunchConfiguration('fcu_url')
    gcs_url = LaunchConfiguration('gcs_url')
    mavros_config_yaml = LaunchConfiguration('mavros_config_yaml')
    mavros_pluginlists_yaml = LaunchConfiguration('mavros_pluginlists_yaml')

    default_bridge_config_path = PathJoinSubstitution([
        FindPackageShare('drone_bringup'),
        'config',
        'bridge.yaml'
    ])

    # Our own copy of mavros's apm_config.yaml (with the distance_sensor
    # subscriber block added) rather than mavros's installed default, so it
    # survives apt updates / workspace rebuilds.
    default_mavros_config_path = PathJoinSubstitution([
        FindPackageShare('drone_bringup'),
        'config',
        'apm_config.yaml'
    ])

    default_mavros_pluginlists_path = PathJoinSubstitution([
        FindPackageShare('mavros'),
        'launch',
        'apm_pluginlists.yaml'
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

    declare_fcu_url = DeclareLaunchArgument(
        'fcu_url',
        default_value='udp://127.0.0.1:14550@127.0.0.1:14557',
        description='MAVLink FCU connection URL (bind@remote)'
    )

    declare_gcs_url = DeclareLaunchArgument(
        'gcs_url',
        default_value='',
        description='Optional GCS passthrough URL'
    )

    declare_mavros_config_yaml = DeclareLaunchArgument(
        'mavros_config_yaml',
        default_value=default_mavros_config_path,
        description='Path to mavros apm_config.yaml (our copy, with distance_sensor added)'
    )

    declare_mavros_pluginlists_yaml = DeclareLaunchArgument(
        'mavros_pluginlists_yaml',
        default_value=default_mavros_pluginlists_path,
        description='Path to mavros apm_pluginlists.yaml'
    )

    # Gazebo to ROS Bridge Node
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

    # MAVROS, included via its own apm.launch so plugin naming/params
    # always match the installed MAVROS version.
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
            'config_yaml': mavros_config_yaml,
            'pluginlists_yaml': mavros_pluginlists_yaml,
        }.items(),
    )

    # rf2o laser odometry -> mavros/odometry/out bridge.
    rf2o_mavros_node = Node(
        package='drone_bringup',
        executable='rf2o_mavros',
        name='rf2o_to_mavros_bridge',
        output='screen',
        parameters=[{'use_sim_time': use_sim_time}],
    )

    # LaserScan rangefinder -> sensor_msgs/Range -> mavros distance_sensor
    # subscriber bridge.
    rangefinder_mavros_node = Node(
        package='drone_bringup',
        executable='rangefinder_to_mavros',
        name='rangefinder_to_mavros_bridge',
        output='screen',
        parameters=[{'use_sim_time': use_sim_time}],
    )

    return LaunchDescription([
        declare_use_sim_time,
        declare_bridge_config,
        declare_fcu_url,
        declare_gcs_url,
        declare_mavros_config_yaml,
        declare_mavros_pluginlists_yaml,
        bridge_node,
        mavros_launch,
        rf2o_mavros_node,
        rangefinder_mavros_node,
    ])
