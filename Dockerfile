FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV GZ_VERSION=harmonic
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TZ=Etc/UTC

# 2. Basics
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    curl \
    gnupg2 \
    lsb-release \
    sudo \
    git \
    build-essential \
    cmake \
    python3-pip \
    python3-dev \
    python3-opencv \
    python3-lxml \
    python3-matplotlib \
    tmux \
    mesa-utils \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    rapidjson-dev \
    libopencv-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-libav \
    gstreamer1.0-gl \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Adding sources

RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" > /etc/apt/sources.list.d/ros2.list
RUN curl -sSL https://packages.osrfoundation.org/gazebo.gpg -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" > /etc/apt/sources.list.d/gazebo-stable.list

#ROS Installation
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-desktop \
    ros-dev-tools \
    python3-colcon-common-extensions \
    gz-harmonic \
    ros-humble-ros-gzharmonic \
    ros-humble-ros-gzharmonic-bridge \
    libgz-sim8-dev \
    && rm -rf /var/lib/apt/lists/*

# Ardupilot
RUN git clone --depth 1 --branch main https://github.com/ArduPilot/ardupilot_gazebo.git /opt/ardupilot_gazebo/src \
    && mkdir /opt/ardupilot_gazebo/build \
    && cd /opt/ardupilot_gazebo/build \
    && cmake ../src -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    && make -j"$(nproc)"

# Permissions
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Making stuff easier
RUN echo "if [ -f /workspace/install/setup.bash ]; then source /workspace/install/setup.bash; fi" >> /home/$USERNAME/.bashrc \
    && echo "source /opt/ros/humble/setup.bash" >> /home/$USERNAME/.bashrc \
    && echo "export GZ_VERSION=harmonic" >> /home/$USERNAME/.bashrc \
    && echo "export GZ_SIM_SYSTEM_PLUGIN_PATH=/opt/ardupilot_gazebo/build:\$GZ_SIM_SYSTEM_PLUGIN_PATH" >> /home/$USERNAME/.bashrc \
    && echo "export GZ_SIM_RESOURCE_PATH=/workspace/SIM/Models:/workspace/SIM/Worlds:/opt/ardupilot_gazebo/src/models:/opt/ardupilot_gazebo/src/worlds:\$GZ_SIM_RESOURCE_PATH" >> /home/$USERNAME/.bashrc \
    && echo "if [ -d \"\$HOME/ardupilot/Tools/autotest\" ]; then export PATH=\$HOME/ardupilot/Tools/autotest:\$PATH; fi" >> /home/$USERNAME/.bashrc

USER $USERNAME
WORKDIR /workspace

CMD ["/bin/bash"]
