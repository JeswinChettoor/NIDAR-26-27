#!/usr/bin/env bash
set -euo pipefail

WORLD="${1:-/workspace/SIM/Worlds/empty.sdf}"

export GZ_VERSION=harmonic
export GZ_SIM_SYSTEM_PLUGIN_PATH="/opt/ardupilot_gazebo/build:${GZ_SIM_SYSTEM_PLUGIN_PATH:-}"
export GZ_SIM_RESOURCE_PATH="/workspace/SIM/Models:/workspace/SIM/Worlds:/opt/ardupilot_gazebo/src/models:/opt/ardupilot_gazebo/src/worlds:${GZ_SIM_RESOURCE_PATH:-}"

echo "Starting Gazebo Harmonic: ${WORLD}"
gz sim -v4 -r "${WORLD}"
