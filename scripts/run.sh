#!/usr/bin/env bash
set -euo pipefail

# 1. Allow local GUI connections
xhost +local:docker > /dev/null 2>&1 || true

# 2. Make sure ~/.Xauthority exists before we bind-mount it.
#    If it's missing, Docker silently creates an empty *directory* at that
#    path instead of mounting a file, which breaks GUI auth with confusing
#    "cannot open display" errors.
touch ~/.Xauthority

# 3. Silently remove old container if it exists (ignoring missing container errors)
docker rm -f nidar_airmouse_dev > /dev/null 2>&1 || true

# 4. Build container with host UID/GID
#    (no `|| true` here on purpose — with `set -e` above, a failed build now
#    stops the script instead of silently falling through to `run` with a
#    stale/missing image)
docker compose build --build-arg USER_UID="$(id -u)" --build-arg USER_GID="$(id -g)"

# 5. Run interactive container explicitly named nidar_airmouse_dev
docker compose run --rm --name nidar_airmouse_dev nidar_sim
