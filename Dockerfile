FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

# 1. System packages, build utilities, and graphics libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales curl gnupg2 lsb-release sudo git build-essential \
    python3-pip python3-dev python3-opencv python3-wxgtk4.0 python3-matplotlib python3-lxml python3-pygame \
    tmux mesa-utils libgl1-mesa-dri libgl1-mesa-glx libegl1 libgles2 net-tools \
    gawk ccache make cmake libtool-bin ppp \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# 2. Official ROS 2 Humble and Gazebo Harmonic repositories
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" > /etc/apt/sources.list.d/ros2.list \
    && curl -sSL https://packages.osrfoundation.org/gazebo.gpg -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable jammy main" > /etc/apt/sources.list.d/gazebo-stable.list

# 3. ROS 2, Gazebo Harmonic, ros_gz bridge, and development headers
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-desktop ros-dev-tools python3-colcon-common-extensions \
    gz-harmonic ros-humble-ros-gzharmonic \
    libgz-sim8-dev rapidjson-dev libopencv-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl \
    && rm -rf /var/lib/apt/lists/*

# 4. MAVProxy, pymavlink, and ArduPilot Python runtime modules
RUN pip3 install --no-cache-dir \
    MAVProxy pymavlink future pexpect dronecan ptyprocess empy==3.3.4 flake8 attrdict3

# 5. Non-root user matching host UID/GID
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && usermod -aG dialout,video $USERNAME

# 6. Sourcing and environment paths in developer's .bashrc
RUN echo "source /opt/ros/humble/setup.bash" >> /home/$USERNAME/.bashrc \
    && echo 'if [ -f /workspace/install/setup.bash ]; then source /workspace/install/setup.bash; fi' >> /home/$USERNAME/.bashrc \
    && echo 'export PATH="/workspace/ardupilot/Tools/autotest:$HOME/.local/bin:/usr/lib/ccache:$PATH"' >> /home/$USERNAME/.bashrc \
    && echo 'export GZ_SIM_SYSTEM_PLUGIN_PATH="/workspace/ardupilot_gazebo/build:$GZ_SIM_SYSTEM_PLUGIN_PATH"' >> /home/$USERNAME/.bashrc \
    && echo 'export GZ_SIM_RESOURCE_PATH="/workspace/SIM/Models:/workspace/SIM/Worlds:/workspace/ardupilot_gazebo/models:/workspace/ardupilot_gazebo/worlds:$GZ_SIM_RESOURCE_PATH"' >> /home/$USERNAME/.bashrc

USER $USERNAME
WORKDIR /workspace

CMD ["/bin/bash"]
