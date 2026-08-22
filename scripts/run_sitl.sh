#!/usr/bin/env bash
set -euo pipefail
# Ensure local user binaries and ArduPilot tools are in PATH
export PATH="$HOME/.local/bin:$HOME/ardupilot/Tools/autotest:$PATH"
export PATH="/usr/lib/ccache:$PATH"
PARAM_FILE="/workspace/SIM/config/x3_no_gps.parm"

if [[ ! -d "${HOME}/ardupilot" ]]; then
    echo "ArduPilot not found. Run: bash /workspace/scripts/setup_ardupilot.sh"
    exit 1
fi

cd "${HOME}/ardupilot"

# shellcheck disable=SC1090
source "${HOME}/.profile" 2>/dev/null || true
export PATH="${HOME}/ardupilot/Tools/autotest:${PATH}"

echo "Starting ArduPilot SITL (no-GPS params: ${PARAM_FILE})"
sim_vehicle.py -v ArduCopter -f gazebo-iris --model JSON \
    --add-param-file="${PARAM_FILE}" \
    --map --console "$@"
