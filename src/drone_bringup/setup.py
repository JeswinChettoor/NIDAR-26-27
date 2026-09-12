import os
from glob import glob
from setuptools import find_packages, setup

package_name = 'drone_bringup'

setup(
    name=package_name,
    version='0.0.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        (os.path.join('share', package_name, 'launch'), glob(os.path.join('launch', '*launch.[pxy][yma]*'))),
        (os.path.join('share', package_name, 'config'), glob(os.path.join('config', '*.yaml'))),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='developer',
    maintainer_email='developer@todo.todo',
    description='Bringup package for drone simulation and odometry pipeline',
    license='Apache-2.0',
    entry_points={
        'console_scripts': [
            'rf2o_mavros = drone_bringup.rf2o_mavros:main',
            'rangefinder_to_mavros = drone_bringup.rangefinder_to_mavros:main',
        ],
    },
)
