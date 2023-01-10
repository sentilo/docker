#!/bin/bash

# variables used into the docker-compose.yml
export SENTILO_VERSION="2.0.0"
export COMPOSE_PROJECT_NAME="Sentilo${SENTILO_VERSION}"
export REDIS_VERSION="6.2.6-alpine"
export MONGO_VERSION="4.4.2-bionic"

# Initial platform image conf files dir
# All them had been configured to run into docker ecosystem
# They are mandatory
export SENTILO_CONF_DIR="./conf"

echo "==========================================================="
echo " Stopping Stentilo v$SENTILO_VERSION docker"
echo "==========================================================="

echo "Stopping Sentilo v$SENTILO_VERSION..."

docker-compose stop
if [ $? -ne 0 ]; then
	echo ""
	echo "ERROR: An error occurred while stopping the docker services."
	echo "Look above traces for more info."
	echo ""
	echo "Now exiting..."
	exit -1
fi

echo ""
echo "Done!"

exit 0
