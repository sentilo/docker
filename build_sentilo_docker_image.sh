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
echo " Building Sentilo v$SENTILO_VERSION docker"
echo "==========================================================="

if [ ! -d "$SENTILO_CONF_DIR" ]; then
	echo "ERROR: $SENTILO_CONF_DIR folder doesn't exists. Please, create it and deploy into it the Sentilo conf files before run this script"
	echo "Fail"
	echo ""
	exit -1
fi

# Remove previous images
echo "Removing previous images for Sentilo v$SENTILO_VERSION docker"
docker-compose rm -fsv
rm -rf ./logs

sleep 2

echo ""
echo "Start building your Sentilo v$SENTILO_VERSION docker image:"
echo ""
sleep 2

# build docker image
docker-compose build --no-cache --pull
if [ $? -ne 0 ]; then
	echo ""
	echo "An error occurred while building the docker services."
	echo "Stopping Sentilo docker image build process."
	echo ""
	exit -1
fi

# create docker services
docker-compose up --no-start --force-recreate
if [ $? -ne 0 ]; then
	echo ""
	echo "An error occurred while creating the docker services."
	echo "Stopping Sentilo docker image build process."
	echo ""
	exit -1
fi

echo ""
echo "Done!"
echo ""

echo "Now you can start your Sentilo v$SENTILO_VERSION docker container with: $ start_sentilo_docker.sh"

exit 0;