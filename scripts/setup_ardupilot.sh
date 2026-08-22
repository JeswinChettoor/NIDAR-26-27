#!/usr/bin/env bash
set -euo pipefail

# One-time setup: clone and build ArduPilot SITL inside the dev container.
# The Gazebo Fortress + ArduPilot plugin are already baked into the Docker image.

ARDUPILOT_DIR="${HOME}/ardupilot"

if [[ -d "${ARDUPILOT_DIR}/.git" ]]; then
    echo "ArduPilot already cloned at ${ARDUPILOT_DIR}"
else
    echo "Cloning ArduPilot (this takes a few minutes)..."
    git clone --recurse-submodules https://github.com/ArduPilot/ardupilot.git "${ARDUPILOT_DIR}"
fi

cd "${ARDUPILOT_DIR}"
if [[ ! -f "${HOME}/.ardupilot_prereqs_done" ]]; then
    echo "Installing ArduPilot build prerequisites..."
    ./Tools/environment_install/install-prereqs-ubuntu.sh -y
    touch "${HOME}/.ardupilot_prereqs_done"
fi

# install-prereqs-ubuntu.sh appends its PATH/env exports to ~/.bashrc, not
# ~/.profile, so pull in both here to make sure *this* shell has them too.
# shellcheck disable=SC1090
source "${HOME}/.bashrc" 2>/dev/null || true
# shellcheck disable=SC1090
source "${HOME}/.profile" 2>/dev/null || true

echo "Building ArduPilot SITL (first build is slow)..."
./waf configure --board sitl
./waf copter

echo ""
echo "ArduPilot SITL ready."
echo "Verify: sim_vehicle.py --help | head -1"
echo ""
echo "NOTE: open any *new* terminal with ./enter.sh before running"
echo "      run_sitl.sh — new interactive shells pick up ~/.bashrc"
echo "      automatically, this current shell already has been patched."
