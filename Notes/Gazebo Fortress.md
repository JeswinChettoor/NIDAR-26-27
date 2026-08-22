Installation guide (Ubuntu 22.04 + ROS 2 Humble):

https://gazebosim.org/docs/fortress/install_ubuntu/

For this project, Gazebo Fortress is installed automatically via:

```bash
sudo apt install ros-humble-ros-gz
```

Do **not** install `gz-harmonic` or `ros-humble-ros-gzharmonic` alongside — they conflict with the official Humble pairing.

Verify:

```bash
gz sim --versions   # should show 6.x (Fortress)
echo $GZ_VERSION    # fortress
```
