#!/usr/bin/env bash
# Grant GUI permissions to local Docker containers
xhost +local:docker > /dev/null 2>&1

# Build image dynamically with host UID/GID if not already built
docker compose build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g)

# Launch the interactive container
docker compose run --rm nidar_sim
