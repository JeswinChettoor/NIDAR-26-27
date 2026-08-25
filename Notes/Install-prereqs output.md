Installing collected packages: setuptools, pip, packaging, wheel
  WARNING: The scripts pip, pip3 and pip3.10 are installed in '/home/developer/.local/bin' which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
  WARNING: The script wheel is installed in '/home/developer/.local/bin' which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
Successfully installed packaging-26.3 pip-26.2.1 setuptools-84.0.0 wheel-0.48.0



## Steps
```
# 1. Navigate to the installer directory
cd /workspace/ardupilot/Tools/environment_install

# 2. Define the missing USER variable
export USER=developer

# 3. Ensure execution permissions
chmod +x install-prereqs-ubuntu.sh

# 4. Run the installer non-interactively
./install-prereqs-ubuntu.sh -y

# 5. Reload your environment paths and aliases
source ~/.bashrc
```

## To start
docker compose down
docker compose up -d --build
docker exec -it nidar-container bash
cd /workspace/ardupilot
git submodule update --init --recursive
./waf configure --board sitl
./waf copter


echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
source ~/.bashrc



sudo apt update
sudo apt install libgz-sim8-dev rapidjson-dev
sudo apt install libopencv-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl


sudo apt-get update
sudo apt-get install -y --no-install-recommends software-properties-common
sudo add-apt-repository -y universe
sudo apt-get update
sudo apt-get install -y --no-install-recommends python3-rosdep


After logging in as root 
```
# Update and install system dependencies
apt-get update && apt-get install -y curl gnupg2 lsb-release

# Add the ROS key and repository list
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
echo "deb [arch=$(dpkg --print-architecture)] http://ros.org $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list

# Install the rosdep binary
apt-get update && apt-get install -y python3-rosdep

# Initialize database (as root)
rosdep init

# Update database (as a normal user, or add --allow-root if you must stay root)
rosdep update

```


