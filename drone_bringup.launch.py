import os
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch.launch_description_sources import AnyLaunchDescriptionSource
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    bridge_config = LaunchConfiguration('bridge_config')
    fcu_url = LaunchConfiguration('fcu_url')
    gcs_url = LaunchConfiguration('gcs_url')
    use_sim_time = LaunchConfiguration('use_sim_time')

    declare_bridge_config = DeclareLaunchArgument(
        'bridge_config',
        default_value=os.path.join(os.path.dirname(__file__), 'bridge.yaml'),
        description='Path to ros_gz_bridge parameter_bridge YAML config'
    )

    declare_fcu_url = DeclareLaunchArgument(
        'fcu_url',
        default_value='udp://127.0.0.1:14550@127.0.0.1:14557',
        description='MAVLink FCU URL that MAVROS connects to'
    )

    declare_gcs_url = DeclareLaunchArgument(
        'gcs_url',
        default_value='',
        description='Optional GCS passthrough URL for MAVROS'
    )

    declare_use_sim_time = DeclareLaunchArgument(
        'use_sim_time',
        default_value='true',
        description='Use /clock from Gazebo instead of wall time'
    )

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

    mavros_launch = IncludeLaunchDescription(
        AnyLaunchDescriptionSource(
            PathJoinSubstitution([
                get_package_share_directory('mavros'),
                'launch',
                'apm.launch',
            ])
        ),
        launch_arguments={
            'fcu_url': fcu_url,
            'gcs_url': gcs_url,
            'use_sim_time': use_sim_time,
        }.items(),
    )

    return LaunchDescription([
        declare_bridge_config,
        declare_fcu_url,
        declare_gcs_url,
        declare_use_sim_time,
        bridge_node,
        mavros_launch,
    ])
