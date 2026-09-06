cmake_minimum_required(VERSION 3.8)
project(lidar_preprocessing)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Enforce C++17
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(tf2 REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)

# scan_preprocessor
add_executable(scan_preprocessor src/scan_preprocessor.cpp)
ament_target_dependencies(scan_preprocessor
  rclcpp 
  sensor_msgs 
  geometry_msgs 
  tf2 
  tf2_geometry_msgs
)

# odom_bridge
add_executable(odom_bridge src/odom_bridge.cpp)
ament_target_dependencies(odom_bridge 
  rclcpp 
  nav_msgs 
  geometry_msgs
)

# Install binaries
install(TARGETS 
  scan_preprocessor 
  odom_bridge 
  DESTINATION lib/${PROJECT_NAME}
)

# Install launch files (ensure a 'launch' directory exists)
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/launch")
  install(DIRECTORY
    launch
    DESTINATION share/${PROJECT_NAME}/
  )
endif()

ament_package()
