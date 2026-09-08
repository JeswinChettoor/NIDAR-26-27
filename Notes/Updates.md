# September 7
- Realised laser odometry and all of that was not needed
- Removing all of that 
- Changing params to rely only on ekf3 from the drone

## September 8
#### Things to do 
- Goal is to get slam toolbox running + get the drone to fly in guided or guided no gps mode.
- Also make sure rangefinder is available to ardupilot 
- Handle conversions.
- Install mission planner
#### Done
- Removed everything back to only have ros gazebo bridge. 
- Removed some params which were not needed.
- Talked to anant  about the guided mode .
- Fixed params to use barometer for height instead of rangefinder , in irl , it would be just one param change. Ardupilot also handles tilt compensation for rangefinder.
- 