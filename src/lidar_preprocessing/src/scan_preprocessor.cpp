#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/laser_scan.hpp>
#include <sensor_msgs/msg/imu.hpp>
#include <geometry_msgs/msg/quaternion.hpp>
#include <tf2/LinearMath/Quaternion.h>
#include <tf2/LinearMath/Matrix3x3.h>
#include <tf2_geometry_msgs/tf2_geometry_msgs.hpp>
#include <cmath>

class ScanPreprocessor : public rclcpp::Node
{
public:
    ScanPreprocessor() : Node("scan_preprocessor")
    {
        // Parameters
        this->declare_parameter<double>("max_tilt_deg", 20.0);
        this->declare_parameter<double>("height_gate_m", 0.20);
        this->declare_parameter<double>("min_range_m", 0.15);   // body footprint rejection
        this->declare_parameter<double>("max_range_m", 10.0);

        max_tilt_rad_ = this->get_parameter("max_tilt_deg").as_double() * M_PI / 180.0;
        height_gate_ = this->get_parameter("height_gate_m").as_double();
        min_range_ = this->get_parameter("min_range_m").as_double();
        max_range_ = this->get_parameter("max_range_m").as_double();

        // Subscribers configured with SensorDataQoS (Best Effort)
        imu_sub_ = this->create_subscription<sensor_msgs::msg::Imu>(
            "/mavros/imu/data",
            rclcpp::SensorDataQoS(),
            std::bind(&ScanPreprocessor::imuCallback, this, std::placeholders::_1));

        scan_sub_ = this->create_subscription<sensor_msgs::msg::LaserScan>(
            "/scan",
            rclcpp::SensorDataQoS(),
            std::bind(&ScanPreprocessor::scanCallback, this, std::placeholders::_1));

        // Publisher
        scan_pub_ = this->create_publisher<sensor_msgs::msg::LaserScan>("/scan_stabilized", 10);

        RCLCPP_INFO(this->get_logger(), "Scan preprocessor started");
    }

private:
    void imuCallback(const sensor_msgs::msg::Imu::SharedPtr msg)
    {
        latest_imu_ = *msg;
        has_imu_ = true;

        // Attitude gating check
        tf2::Quaternion q;
        tf2::fromMsg(msg->orientation, q);
        tf2::Matrix3x3 m(q);
        double roll, pitch, yaw;
        m.getRPY(roll, pitch, yaw);

        if (std::abs(roll) > max_tilt_rad_ || std::abs(pitch) > max_tilt_rad_)
        {
            tilt_exceeded_ = true;
        }
        else
        {
            tilt_exceeded_ = false;
        }
    }

    void scanCallback(const sensor_msgs::msg::LaserScan::SharedPtr msg)
    {
        if (!has_imu_)
        {
            RCLCPP_WARN_THROTTLE(this->get_logger(), *this->get_clock(), 5000,
                "No IMU data yet, skipping scan");
            return;
        }

        if (tilt_exceeded_)
        {
            RCLCPP_WARN_THROTTLE(this->get_logger(), *this->get_clock(), 5000,
                "Tilt exceeded, gating scan output");
            return;  // Do not publish during excessive tilt
        }

        // Deroll/depitch: rotate scan points using IMU quaternion
        sensor_msgs::msg::LaserScan stabilized = *msg;
        stabilized.header.frame_id = "base_stabilized";
        stabilized.ranges.clear();
        stabilized.intensities.clear();

        tf2::Quaternion q_imu;
        tf2::fromMsg(latest_imu_.orientation, q_imu);
        tf2::Matrix3x3 rot(q_imu);
        double roll, pitch, yaw;
        rot.getRPY(roll, pitch, yaw);

        // Build inverse rotation: we want to cancel roll and pitch
        tf2::Quaternion q_level;
        q_level.setRPY(-roll, -pitch, 0.0);  // Keep yaw = 0 (LiDAR frame yaw is arbitrary)

        for (size_t i = 0; i < msg->ranges.size(); ++i)
        {
            float r = msg->ranges[i];
            if (std::isinf(r) || std::isnan(r) || r < min_range_ || r > max_range_)
            {
                stabilized.ranges.push_back(std::numeric_limits<float>::infinity());
                if (!msg->intensities.empty())
                    stabilized.intensities.push_back(0.0);
                continue;
            }

            float angle = msg->angle_min + i * msg->angle_increment;
            float x = r * std::cos(angle);
            float y = r * std::sin(angle);
            float z = 0.0;

            // Rotate point to cancel roll/pitch
            tf2::Vector3 p(x, y, z);
            tf2::Vector3 p_level = tf2::quatRotate(q_level, p);

            // Height gating: only keep points within ±height_gate_m of the "floor" plane
            if (std::abs(p_level.z()) > height_gate_)
            {
                stabilized.ranges.push_back(std::numeric_limits<float>::infinity());
                if (!msg->intensities.empty())
                    stabilized.intensities.push_back(0.0);
                continue;
            }

            // Project back to 2D in base_stabilized frame
            float r_level = std::sqrt(p_level.x() * p_level.x() + p_level.y() * p_level.y());

            stabilized.ranges.push_back(r_level);
            if (!msg->intensities.empty())
                stabilized.intensities.push_back(msg->intensities[i]);
        }

        scan_pub_->publish(stabilized);
    }

    rclcpp::Subscription<sensor_msgs::msg::LaserScan>::SharedPtr scan_sub_;
    rclcpp::Subscription<sensor_msgs::msg::Imu>::SharedPtr imu_sub_;
    rclcpp::Publisher<sensor_msgs::msg::LaserScan>::SharedPtr scan_pub_;

    sensor_msgs::msg::Imu latest_imu_;
    bool has_imu_ = false;
    bool tilt_exceeded_ = false;

    double max_tilt_rad_;
    double height_gate_;
    double min_range_;
    double max_range_;
};

int main(int argc, char** argv)
{
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<ScanPreprocessor>());
    rclcpp::shutdown();
    return 0;
}
