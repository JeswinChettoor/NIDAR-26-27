export GZ_VERSION=fortress
export GZ_SIM_RESOURCE_PATH="/workspace/SIM/Models:/workspace/SIM/Worlds:${GZ_SIM_RESOURCE_PATH:-}"

# Empty world with X3 already included
bash /workspace/scripts/run_gazebo.sh /workspace/SIM/Worlds/empty.sdf

# Or arena maze:
# bash /workspace/scripts/run_gazebo.sh /workspace/SIM/Worlds/world_standard.sdf

# Spawn manually (if world has no include):
# gz service -s /world/empty/create \
#   --reqtype gz.msgs.EntityFactory \
#   --reptype gz.msgs.Boolean \
#   --timeout 5000 \
#   --req "sdf_filename: '/workspace/SIM/Models/X3/model.sdf', name: 'X3', pose: {position: {x: 0.0, y: 0.0, z: 0.5}}"
