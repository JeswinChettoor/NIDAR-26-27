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
