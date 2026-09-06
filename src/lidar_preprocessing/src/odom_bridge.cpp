#include <rclcpp/rclcpp.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <geometry_msgs/msg/twist_with_covariance.hpp>

class OdomBridge : public rclcpp::Node
{
public:
    OdomBridge() : Node("odom_bridge")
    {
        this->declare_parameter<double>("max_accel_xy", 5.0);  // m/s²
        this->declare_parameter<double>("max_speed_xy", 10.0); // m/s

        max_accel_ = this->get_parameter("max_accel_xy").as_double();
        max_speed_ = this->get_parameter("max_speed_xy").as_double();

        odom_sub_ = this->create_subscription<nav_msgs::msg::Odometry>(
            "/odom_rf2o", 10,
            std::bind(&OdomBridge::odomCallback, this, std::placeholders::_1));

        odom_pub_ = this->create_publisher<nav_msgs::msg::Odometry>("/mavros/odometry/out", 10);

        RCLCPP_INFO(this->get_logger(), "Odom bridge started");
    }

private:
    void odomCallback(const nav_msgs::msg::Odometry::SharedPtr msg)
    {
        // Validation: check for NaN/Inf
        if (!std::isfinite(msg->twist.twist.linear.x) ||
            !std::isfinite(msg->twist.twist.linear.y))
        {
            RCLCPP_WARN_THROTTLE(this->get_logger(), *this->get_clock(), 5000,
                "Invalid velocity from RF2O, dropping");
            return;
        }

        // Validation: speed limit
        double speed = std::hypot(msg->twist.twist.linear.x, msg->twist.twist.linear.y);
        if (speed > max_speed_)
        {
            RCLCPP_WARN_THROTTLE(this->get_logger(), *this->get_clock(), 5000,
                "Speed %.2f exceeds limit, dropping", speed);
            return;
        }

        // Validation: covariance degeneracy (check determinant or diagonal)
        double cov_xx = msg->twist.covariance[0];
        double cov_yy = msg->twist.covariance[7];
        if (cov_xx > 1.0 || cov_yy > 1.0)
        {
            RCLCPP_WARN_THROTTLE(this->get_logger(), *this->get_clock(), 5000,
                "High covariance [%.3f, %.3f], dropping", cov_xx, cov_yy);
            return;
        }

        // Republish for MAVROS with correct frames
        nav_msgs::msg::Odometry out = *msg;
        out.header.frame_id = "odom";
        out.child_frame_id = "base_link";

        // IMPORTANT: Only velocity is trusted. Zero out position to prevent
        // EKF3 from fusing accumulated drift.
        out.pose.pose.position.x = 0.0;
        out.pose.pose.position.y = 0.0;
        out.pose.pose.position.z = 0.0;
        out.pose.covariance = {};  // Zero covariance = don't fuse position

        odom_pub_->publish(out);
    }

    rclcpp::Subscription<nav_msgs::msg::Odometry>::SharedPtr odom_sub_;
    rclcpp::Publisher<nav_msgs::msg::Odometry>::SharedPtr odom_pub_;
    double max_accel_, max_speed_;
};

int main(int argc, char** argv)
{
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<OdomBridge>());
    rclcpp::shutdown();
    return 0;
}