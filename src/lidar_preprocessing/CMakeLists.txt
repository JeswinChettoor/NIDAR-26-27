cmake_minimum_required(VERSION 3.8)
project(lidar_preprocessing)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(tf2 REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)

add_executable(scan_preprocessor src/scan_preprocessor.cpp)
ament_target_dependencies(scan_preprocessor
  rclcpp sensor_msgs geometry_msgs tf2 tf2_geometry_msgs nav_msgs
)

install(TARGETS scan_preprocessor DESTINATION lib/${PROJECT_NAME})

ament_package()
