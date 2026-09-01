FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# ==============================================================================
# 1. Base Tools, Sudo, Locales & Build Essentials
# ==============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
        locales curl wget gnupg lsb-release ca-certificates \
        software-properties-common git sudo python3-pip python3-dev \
        cmake build-essential ccache gawk pkg-config \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# 2. Gazebo Harmonic Official Apt Repository & Libraries
# ==============================================================================
RUN wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null \
    && apt-get update && apt-get install -y --no-install-recommends \
        gz-harmonic \
        libgz-sim8-dev \
        libgz-transport13-dev \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# 3. GPU / GUI Runtime Libraries & DRI Symlinks (X11 / Wayland Support)
# ==============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgl1-mesa-glx libgl1-mesa-dri libegl1 libegl-mesa0 libglu1-mesa libosmesa6 \
        mesa-utils x11-utils x11-apps \
        libxcb-xinerama0 libxkbcommon-x11-0 \
    && mkdir -p /usr/lib/dri \
    && ln -sf /usr/lib/x86_64-linux-gnu/dri/* /usr/lib/dri/ \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# 4. ROS 2 Humble Repository & Desktop Installation
# ==============================================================================
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" \
        | tee /etc/apt/sources.list.d/ros2.list > /dev/null \
    && apt-get update && apt-get install -y --no-install-recommends \
        ros-humble-desktop \
        python3-colcon-common-extensions \
        python3-rosdep \
    && rosdep init \
    && rosdep update \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# 5. Gazebo Harmonic <-> ROS 2 Bridge (ros_gz)
# ==============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-humble-ros-gzharmonic \
        ros-humble-ros-gzharmonic-bridge \
        ros-humble-ros-gzharmonic-interfaces \
        ros-humble-ros-gzharmonic-sim \
    && rm -rf /var/lib/apt/lists/*
# ==============================================================================
# 6. MAVROS, GeographicLib & SITL Python Dependencies
# ==============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-humble-mavros \
        ros-humble-mavros-msgs \
        ros-humble-geographic-msgs \
        geographiclib-tools \
        python3-opencv \
        python3-wxgtk4.0 \
        libgtk-3-dev \
        libnotify-dev \
        libsdl2-dev \
    && /opt/ros/humble/lib/mavros/install_geographiclib_datasets.sh \
    && pip3 install --no-cache-dir \
        pymavlink \
        MAVProxy \
        dronecan \
        pexpect \
        future \
        transforms3d \
        matplotlib \
        scipy \
    && pip3 install --no-cache-dir \
        -f https://extras.wxpython.org/wxPython4/extras/linux/gtk3/ubuntu-22.04 \
        wxPython \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# 7. GPS-Denied Navigation Stack (SLAM Toolbox, Nav2, RF2O, TF2)
# ==============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-humble-slam-toolbox \
        ros-humble-navigation2 \
        ros-humble-nav2-bringup \
        ros-humble-tf-transformations \
        ros-humble-tf2-ros \
    && rm -rf /var/lib/apt/lists/*
    
RUN mkdir -p /tmp/rf2o_ws/src && \
    cd /tmp/rf2o_ws/src && \
    git clone https://github.com/MAPIRlab/rf2o_laser_odometry.git -b ros2 && \
    cd /tmp/rf2o_ws && \
    . /opt/ros/humble/setup.sh && \
    colcon build --symlink-install --install-base /opt/ros/humble --merge-install && \
    rm -rf /tmp/rf2o_ws
# ==============================================================================
# 8. User Creation & Sudo Permissions
# ==============================================================================
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

RUN (groupadd --gid $USER_GID $USERNAME 2>/dev/null || true) && \
    (groupadd -f render) && \
    (groupadd -f video) && \
    (useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME 2>/dev/null || true) && \
    usermod -aG sudo,video,render $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "$USERNAME:$USERNAME" | chpasswd

# ==============================================================================
# 9. Workspace Setup & Environment Variables
# ==============================================================================
WORKDIR /workspace
ENV USER=$USERNAME
ENV GZ_VERSION=harmonic
ENV XDG_RUNTIME_DIR=/tmp/runtime-$USERNAME

# Preset Gazebo search paths for models, worlds, and plugins
ENV GZ_SIM_SYSTEM_PLUGIN_PATH=/workspace/ardupilot_gazebo/build:$GZ_SIM_SYSTEM_PLUGIN_PATH
ENV GZ_SIM_RESOURCE_PATH=/workspace/SIM/Models:/workspace/SIM/Worlds:/workspace/ardupilot_gazebo/models:/workspace/ardupilot_gazebo/worlds:$GZ_SIM_RESOURCE_PATH

# ArduPilot autotest and local binary paths
ENV PATH=/home/$USERNAME/.local/bin:/workspace/ardupilot/Tools/autotest:$PATH

# Create runtime directory with proper ownership
RUN mkdir -p /tmp/runtime-$USERNAME && chmod 700 /tmp/runtime-$USERNAME && chown -R $USERNAME:$USERNAME /tmp/runtime-$USERNAME
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME /workspace

# Switch to developer user
USER $USERNAME

# ==============================================================================
# 10. Persistent Shell Sourcing (.bashrc)
# ==============================================================================
RUN echo "source /opt/ros/humble/setup.bash" >> /home/$USERNAME/.bashrc && \
    echo "if [ -f /home/$USERNAME/drone_ws/install/setup.bash ]; then source /home/$USERNAME/drone_ws/install/setup.bash; fi" >> /home/$USERNAME/.bashrc && \
    echo "export PATH=/home/$USERNAME/.local/bin:/workspace/ardupilot/Tools/autotest:\$PATH" >> /home/$USERNAME/.bashrc

WORKDIR /workspace
CMD ["/bin/bash"]
