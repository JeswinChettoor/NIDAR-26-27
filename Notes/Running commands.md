export GZ_SIM_RESOURCE_PATH="$(pwd)/SIM/Models:$GZ_SIM_RESOURCE_PATH"
gz sim SIM/Worlds/world_standard.sdf -r

gz service -s /world/arena_world/create \
  --reqtype gz.msgs.EntityFactory \
  --reptype gz.msgs.Boolean \
  --timeout 1000 \
  --req "sdf_filename: '$(pwd)/SIM/Models/X3/model.sdf', name: 'X3', pose: {position: {x: 0.0, y: 0.0, z: 0.5}}"


