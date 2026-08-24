### To get root privileges 
docker compose exec -u 0 gazebo bash
apt-get update && apt-get install -y git
exit
docker compose exec gazebo bash
