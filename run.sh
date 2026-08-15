#!/usr/bin/env bash

# 1. Allow local GUI connections
xhost +local:docker > /dev/null 2>&1 || true

# 2. Silently remove old container if it exists (ignoring missing container errors)
docker rm -f nidar_airmouse_dev 2>/dev/null || true

# 3. Build container with host UID/GID
docker compose build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g)

# 4. Run interactive container explicitly named nidar_airmouse_dev
docker compose run --rm --name nidar_airmouse_dev nidar_sim

