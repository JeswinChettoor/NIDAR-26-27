import os
from glob import glob
from setuptools import find_packages, setup

package_name = 'lidar_tilt_compensator'

setup(
    name=package_name,
    version='0.0.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        (os.path.join('share', package_name, 'config'), glob('config/*.yaml')),
        # ADD THIS NEW LINE FOR THE LAUNCH FILE:
        (os.path.join('share', package_name, 'launch'), glob('launch/*.launch.py')),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='developer',
    maintainer_email='developer@todo.todo',
    description='LiDAR tilt compensation pipeline',
    license='TODO: License declaration',
    entry_points={
        'console_scripts': [
            'scan_to_cloud_node = lidar_tilt_compensator.scan_to_cloud_node:main',
        ],
    },
)
