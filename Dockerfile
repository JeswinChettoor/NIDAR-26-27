FROM ubuntu:22.04

# 1. Non-interactive frontend and locale configuration
ENV DEBIAN_FRONTEND=noninteractive
ENV GZ_VERSION=harmonic
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# 2. Base utilities, compilation tools, and graphics libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    curl \
    gnupg2 \
    lsb-release \
    sudo \
    git \
    build-essential \
    python3-pip \
    tmux \
    mesa-utils \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# 3. Add official ROS 2 Humble APT repository
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" > /etc/apt/sources.list.d/ros2.list

# 4. Add official Open Robotics (Gazebo) APT repository
RUN curl -sSL https://packages.osrfoundation.org/gazebo.gpg -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable jammy main" > /etc/apt/sources.list.d/gazebo-stable.list

# 5. Install ROS 2 Humble Desktop, Gazebo Harmonic, and ros_gz bridge
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-desktop \
    ros-dev-tools \
    python3-colcon-common-extensions \
    gz-harmonic \
    ros-humble-ros-gzharmonic \
    && rm -rf /var/lib/apt/lists/*

# 6. Non-root user matching the host UID/GID
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "if [ -f /workspace/install/setup.bash ]; then source /workspace/install/setup.bash; fi" >> /home/$USERNAME/.bashrc
# 7. Pre-configure shell auto-sourcing and Gazebo search paths
RUN echo "source /opt/ros/humble/setup.bash" >> /home/$USERNAME/.bashrc \
    && echo "export GZ_SIM_RESOURCE_PATH=\$GZ_SIM_RESOURCE_PATH:/workspace/SIM/Models:/workspace/SIM/Worlds" >> /home/$USERNAME/.bashrc

USER $USERNAME
WORKDIR /workspace

CMD ["/bin/bash"]
