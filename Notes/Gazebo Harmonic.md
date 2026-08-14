Installation guide :
[[https://gazebosim.org/docs/harmonic/install_ubuntu/]]

```
sudo apt-get update
sudo apt-get install curl lsb-release gnupg

sudo curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
sudo apt-get update
sudo apt-get install gz-harmonic
```

```
Use this Gazebo Harmonic-specific version. Gazebo Harmonic is paired with ROS 2 Jazzy, and its Gazebo major version is 8.x. [docs.ros](https://docs.ros.org/en/jazzy/Releases/Release-Jazzy-Jalisco.html)

```text
Create a complete, locally runnable Gazebo Harmonic world for the NIDAR AirMouse GPS-denied indoor search and mapping challenge.

Focus only on the static arena and world structure. Do not create a drone model, sensors, mission timer, battery model, communication model, evaluator, scoring logic, ROS 2 autonomy nodes, or ground-station dashboard.

## Gazebo target

Target:

- Gazebo Harmonic / Gazebo Sim 8.x.
- SDF compatible with Gazebo Harmonic.
- ROS 2 Jazzy compatibility where relevant.
- Use standard Gazebo Sim systems only.
- Do not use Gazebo Classic plugins such as `libgazebo_ros_*`.
- Do not use Fuel, internet services, cloud APIs, external meshes, GPS, GNSS, or external network dependencies.
- Use only local `model://` resources and standard primitive geometry.
- The world must launch with `gz sim`.

## Arena dimensions

Create the complete 15 m × 15 m indoor arena:

```yaml
arena_length: 15.0
arena_width: 15.0
x_min: -7.5
x_max: 7.5
y_min: -7.5
y_max: 7.5
floor_z: 0.0
minimum_corridor_width: 1.0
minimum_doorway_width: 1.0
room_internal_size: [2.0, 2.0]
minimum_vertical_clearance: 2.4384
entry_exit_center: [0.0, -6.8, 0.0]
launch_pad_center: [0.0, -7.1, 0.005]
launch_pad_size: [0.6096, 0.6096, 0.01]
```

Use the complete arena area. Create:

- A rigid floor covering 15 m × 15 m.
- External boundary walls.
- One entry point and the same point as the exit.
- At least 1 m clear width at the entry/exit.
- A visible 0.6096 m × 0.6096 m launch pad.
- Corridors, turns, junctions, rooms, dead ends, and a loop.
- Six accessible rooms.
- Six survivor dummy locations.
- A covered overhead net.

## Fixed maze topology

Create one fixed, fully connected, non-random maze.

Required topology:

```text
ENTRY_EXIT → J1 → J2 → J3 → J4 → RETURN_ROUTE → ENTRY_EXIT

Loop:
J2 → LOOP_A → LOOP_B → J4

Rooms:
J1 → R1
J2 → R2
J2 → R3
J3 → R4
J4 → R5
J4 → R6

Dead ends:
J1 → D1
J3 → D2
```

Include:

- Four major junctions.
- At least six turns.
- At least two T-junctions.
- At least one four-way junction.
- At least one long corridor.
- Two dead ends approximately 3 m long.
- A physically connected loop long enough to test loop closure and backtracking.
- No inaccessible rooms or branches.
- No corridor narrower than 1 m.
- No unnecessarily wide routes.

Use these approximate centreline landmarks:

```yaml
ENTRY_EXIT: [0.0, -6.8]
J1: [0.0, -5.0]
J2: [-2.5, -2.5]
J3: [0.0, 0.0]
J4: [3.0, 2.5]
LOOP_A: [3.0, -1.0]
LOOP_B: [5.0, 1.0]
R1: [-2.0, -5.0]
D1: [2.5, -5.0]
R2: [-4.5, -2.5]
R3: [-2.5, -0.5]
R4: [-2.0, 2.5]
D2: [0.0, 3.5]
R5: [5.0, 2.5]
R6: [3.0, 4.8]
```

Adjust the wall layout when necessary to preserve valid geometry, room dimensions, connectivity, and clearances.

## Walls and net

Use configurable parameters:

```yaml
wall_height: 2.44
wall_thickness: 0.06
net_height: 2.50
corridor_clear_width: 1.0
doorway_clear_width: 1.0
room_internal_size: [2.0, 2.0]
lighting_mode: NORMAL
```

Every wall must contain:

- A visual element.
- A collision element.
- A stable static pose.
- No accidental gaps.
- No collision geometry blocking a doorway.

Use simple box collision geometry. Visual materials may resemble damaged concrete, plywood, or temporary arena panels.

Create two separate overhead-net elements:

1. A semi-transparent visual net.
2. An enabled collision surface at the net height.

The net must prevent vertical escape. The exact net mesh, material, transparency, and height are simulation assumptions unless confirmed by NIDAR organizers.

Do not add an opaque solid ceiling.

## Survivors

Use replaceable local survivor models and place:

```text
R1 → S1: standing, near rear wall, facing corridor
R2 → S2: seated, near room centre, sideways
R3 → S3: lying, near left wall, parallel to wall
R4 → S4: partially occluded by small room clutter
R5 → S5: standing, near right wall, facing away
R6 → S6: seated, near doorway without blocking it, facing a side wall
```

Each survivor must have visual and collision geometry, a unique model name, and configurable position, orientation, and posture.

Survivor appearance, clothing, posture, lighting, and exact placement are simulation assumptions, not official rules.

## Static obstacles and lighting

Add only these simple static obstacles:

- `O1`: floor debris, approximately 0.30 × 0.30 × 0.15 m, in a corridor.
- `O2`: damaged vertical panel near one corridor side without reducing clear passage below 1 m.
- `O3`: small clutter object near S4 for partial occlusion.
- `O4`: small clutter object near S6 that does not block the doorway.

Use an indoor visual environment:

- No sky, outdoor horizon, GPS, GNSS, satellite, or magnetic navigation aids.
- Neutral wall materials.
- Moderate indoor lighting.
- Slightly darker rooms than corridors.
- No room labels, arrows, or maps printed in the environment.

Provide `NORMAL` and configurable `LOW_LIGHT` modes. Do not add smoke, fire, dynamic people, or severe visual effects.

## Private ground truth

Create private YAML metadata containing:

- Room IDs.
- Room centres and bounds.
- Doorway positions.
- Maze connectivity.
- Survivor IDs and positions.
- Obstacle positions.
- Configurable logical grid labels using a 1 m grid convention.

The grid labels and all ground-truth values are simulation metadata, not official competition conventions. Keep them separate from the visible world and clearly mark them as evaluator-only.

## Required files

Generate:

```text
nidar_airmouse_competition.sdf

models/
  maze_wall/
    model.sdf
    model.config
  room/
    model.sdf
    model.config
  survivor_dummy/
    model.sdf
    model.config
  damaged_panel/
    model.sdf
    model.config
  floor_debris/
    model.sdf
    model.config
  overhead_net/
    model.sdf
    model.config

config/
  arena_parameters.yaml
  arena_ground_truth.yaml
  survivor_ground_truth.yaml

README.md
VALIDATION.md
```

The README must explain:

- Gazebo Harmonic and SDF compatibility.
- Required Gazebo/ROS packages.
- How to launch using `gz sim`.
- How to configure `GZ_SIM_RESOURCE_PATH`.
- How to enable LOW_LIGHT mode.
- How to replace survivor models.
- How to isolate or disable ground truth.
- Which values are official rulebook values.
- Which values are engineering assumptions.
- Which values must be confirmed with NIDAR organizers.

## Validation

Before returning the files, validate:

- XML/SDF syntax.
- Gazebo Harmonic compatibility.
- Local resource paths.
- Model names.
- Visual and collision elements.
- Arena dimensions and boundaries.
- Corridor, doorway, and room dimensions.
- Wall and room overlap.
- Entry/exit connectivity.
- Connectivity of all six rooms.
- Connectivity of the loop.
- Reachability of both dead ends.
- Survivor and obstacle placement.
- Net visibility and collision.
- Absence of Gazebo Classic plugins.
- Absence of GPS, GNSS, Fuel, internet, cloud, and external network dependencies.
- Separation of private ground truth from the visible simulation.

Return complete files, not pseudocode. Do not invent or claim unspecified official competition rules.
```
```


