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

# --- GPU / GUI runtime libraries ------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgl1-mesa-glx libgl1-mesa-dri libegl1 libglu1-mesa \
        mesa-utils x11-utils x11-apps \
        libxcb-xinerama0 libxkbcommon-x11-0 \
    && rm -rf /var/lib/apt/lists/*

# --- Robust user creation with passwordless sudo --------------------------
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

RUN (groupadd --gid $USER_GID $USERNAME 2>/dev/null || true) && \
    (useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME 2>/dev/null || true) && \
    usermod -aG sudo $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "$USERNAME:$USERNAME" | chpasswd

# --- Workspace & Environment ----------------------------------------------
WORKDIR /workspace
ENV USER=$USERNAME
ENV GZ_SIM_RESOURCE_PATH=/workspace/SIM/Models
ENV GZ_VERSION=harmonic
ENV XDG_RUNTIME_DIR=/tmp/runtime-$USERNAME

RUN chown -R $USERNAME:$USERNAME /home/$USERNAME
USER $USERNAME

