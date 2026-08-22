# NIDAR Airmouse Simulation

Indoor GPS-denied drone stack: **ROS 2 Humble + Gazebo Fortress + ArduPilot SITL**.

## Quick start

```bash
# 1. Build and enter the dev container
./run.sh

# 2. In the container — one-time ArduPilot setup
bash /workspace/scripts/setup_ardupilot.sh
```

Open extra terminals with `./enter.sh`.

### Terminal 1 — Gazebo (empty world)

```bash
bash /workspace/scripts/run_gazebo.sh
```

### Terminal 2 — ArduPilot SITL (no GPS)

```bash
bash /workspace/scripts/run_sitl.sh
```

In the MAVProxy console:

```
STABILIZE> mode alt_hold
ALT_HOLD> arm throttle
ALT_HOLD> rc 3 1600
```

### Terminal 3 — ROS 2 sensor bridge

```bash
bash /workspace/scripts/run_ros_bridge.sh
```

Verify:

```bash
ros2 topic list
ros2 topic echo /model/X3/lidar/scan --once
```

### Arena maze world

```bash
bash /workspace/scripts/run_gazebo.sh /workspace/SIM/Worlds/world_standard.sdf
```

## Stack

| Layer | Choice |
|---|---|
| ROS 2 | Humble |
| Simulator | Gazebo Fortress (via `ros-humble-ros-gz`) |
| Flight controller | ArduPilot SITL |
| Gazebo plugin | `ardupilot_gazebo` (fortress branch, baked in Docker) |
| Drone model | `SIM/Models/X3/model.sdf` |
| No-GPS params | `SIM/config/x3_no_gps.parm` |

## No-GPS configuration

GPS is disabled in two places:

1. **Gazebo model** — `<have_gps>0</have_gps>` in `ArduPilotPlugin`
2. **ArduPilot params** — `GPS_TYPE=0`, EKF3 sources without GPS in `x3_no_gps.parm`

For autonomous GUIDED flight indoors, you will later feed SLAM/external nav into EKF3 (`EK3_SRC1_POSXY=6`).

## Rebuild container after Dockerfile changes

```bash
./run.sh
```
