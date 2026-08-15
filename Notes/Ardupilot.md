**Setting up ardupilot**
https://github.com/ArduPilot/ardupilot

According to this :

```
git clone --recurse-submodules https://github.com/ArduPilot/ardupilot.git

```
without recurse submodules , half the folders wouldnt have proper content.
To install requirements :
Tools/environment_install/install-prereqs-ubuntu.sh -y

```
echo 'export PATH="/workspace/ardupilot/Tools/autotest:$PATH"' >> ~/.bashrc echo 'export PATH="/usr/lib/ccache:$PATH"' >> ~/.bashrc source ~/.bashrc

./waf configure --board sitl
./waf copter
python3 -m pip install pexpect

pip install --user future pexpect dronecan lxml


sudo apt-get install -y python3-dev python3-opencv python3-wxgtk4.0 python3-pip python3-matplotlib python3-lxml python3-pygame
pip install --user MAVProxy


```
```echo 'export GZ_SIM_SYSTEM_PLUGIN_PATH="/workspace/ardupilot_gazebo/build:$GZ_SIM_SYSTEM_PLUGIN_PATH"' >> ~/.bashrc
echo 'export GZ_SIM_RESOURCE_PATH="/workspace/SIM/Models:/workspace/SIM/Worlds:/workspace/ardupilot_gazebo/models:/workspace/ardupilot_gazebo/worlds:$GZ_SIM_RESOURCE_PATH"' >> ~/.bashrc
echo 'export PATH="/workspace/ardupilot/Tools/autotest:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

https://ardupilot.org/dev/docs/sitl-with-gazebo.html
https://github.com/ArduPilot/ardupilot_gazebo/blob/main/README.md
https://github.com/ArduPilot/ardupilot_gazebo

**Installing libraries**
```
sudo apt update
sudo apt install libgz-sim8-dev rapidjson-dev
sudo apt install libopencv-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl
```
**Setting plugin paths**
```
# Set plugin path to your build directory
export GZ_SIM_SYSTEM_PLUGIN_PATH=/workspace/ardupilot_gazebo/build:$GZ_SIM_SYSTEM_PLUGIN_PATH

# Set resource paths
export GZ_SIM_RESOURCE_PATH=/workspace/ardupilot_gazebo/models:/workspace/ardupilot_gazebo/worlds:$GZ_SIM_RESOURCE_PATH

# This worked after these steps : - a drone came up
gz sim -v4 -r iris_runway.sdf
```

**Have to add this to bashrc file**
```
echo 'export GZ_SIM_SYSTEM_PLUGIN_PATH=$HOME/ardupilot_gazebo/build:${GZ_SIM_SYSTEM_PLUGIN_PATH}' >> ~/.bashrc
echo 'export GZ_SIM_RESOURCE_PATH=$HOME/ardupilot_gazebo/models:$HOME/ardupilot_gazebo/worlds:${GZ_SIM_RESOURCE_PATH}' >> ~/.bashrc
```



