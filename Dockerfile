FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# --- Base tools, sudo, git, locales ---------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        locales curl wget gnupg lsb-release ca-certificates \
        software-properties-common git sudo \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# --- Gazebo Harmonic official apt repo ------------------------------------
RUN wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null \
    && apt-get update && apt-get install -y --no-install-recommends \
        gz-harmonic \
    && rm -rf /var/lib/apt/lists/*

# --- GPU / GUI runtime libraries & DRI Symlinks --------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgl1-mesa-glx libgl1-mesa-dri libegl1 libegl-mesa0 libglu1-mesa libosmesa6 \
        mesa-utils x11-utils x11-apps \
        libxcb-xinerama0 libxkbcommon-x11-0 \
    && mkdir -p /usr/lib/dri \
    && ln -sf /usr/lib/x86_64-linux-gnu/dri/* /usr/lib/dri/ \
    && rm -rf /var/lib/apt/lists/*

# --- Robust user creation with passwordless sudo and GPU groups ----------
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

# --- Workspace & Environment ----------------------------------------------
WORKDIR /workspace
ENV USER=$USERNAME
ENV GZ_VERSION=harmonic
ENV XDG_RUNTIME_DIR=/tmp/runtime-$USERNAME

# Preset complete paths for ArduPilot plugins and simulation models
ENV GZ_SIM_SYSTEM_PLUGIN_PATH=/workspace/ardupilot_gazebo/build:$GZ_SIM_SYSTEM_PLUGIN_PATH
ENV GZ_SIM_RESOURCE_PATH=/workspace/SIM/Models:/workspace/SIM/Worlds:/workspace/ardupilot_gazebo/models:/workspace/ardupilot_gazebo/worlds:$GZ_SIM_RESOURCE_PATH

# Create runtime directory with proper ownership
RUN mkdir -p /tmp/runtime-$USERNAME && chmod 700 /tmp/runtime-$USERNAME && chown -R $USERNAME:$USERNAME /tmp/runtime-$USERNAME
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME

USER $USERNAME
