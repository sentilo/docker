# Sentilo 2.0.0 - Official Platform Docker Image

This repository offers a Docker Compose script with the necessary services to be able to create a Sentilo 2.0.0 platform in your development system.

In addition, several shellscripts are offered that facilitate the creation, start and stop of these services.

## Configuration

### Sentilo .conf files

Prior to the creation of the services, it is necessary to have the Sentilo configuration files duly modified to be able to create the platform within a docker network.

These files are located inside the ***conf*** directory, and the docker containers services will use them as the content of a data volume:

<pre>
sentilo.conf
sentilo-agent-alert.conf
sentilo-agent-location-updater.conf
sentilo-catalog.conf
sentilo-platform.conf
</pre>

These files are prepared to work with a local docker network, called `sentilo_network`, and communication between modules is done by hostname (container name).

### Other services config files

#### Redis

The Redis configuration is located in the `./config/redis/redis.conf` file, and is ready to set up a Redis instance in *standalone* mode.

This file will be mounted as a data volume, so that the Redis service can use it from within the container.

#### Mongo

The Mongo configuration is located in the `./config/mongo/config/mongod.conf` file, and is ready to set up a Mongodb instance in *standalone* mode, with a replicaset named `rs_sentilo`.

Alternatively, three Mongo database initialization files are attached, with the minimum necessary structure and some test entities. They are located into the `./config/mongo/docker-entrypoint-initdb.d' directory:

<pre>
01.create_users.js
02.init_data.js
03.init_test_data.js
</pre>

These files are executed by name order on database init lifecycle.

## Sentilo 2.0.0 platform services

The `docker-compose.yml` file is the Docker Compose descriptor file that will orchestrate the creation and execution of each of the Sentilo 2.0.0 platform images.

Below is the list of services that make up the Sentilo 2.0.0 platform.

These are the versions used for each of them, wich are exported into the build script:

<pre>
SENTILO_VERSION="2.0.0"
COMPOSE_PROJECT_NAME="Sentilo${SENTILO_VERSION}"
REDIS_VERSION="6.2.6-alpine"
MONGO_VERSION="4.4.2-bionic"
</pre>

**NOTE:** For the correct creation of all the platform services, it is essential to have the versions as environment variables, previously exported. If this is not the case, the platform creation and startup script will fail.

#### sentilo-redis

***Redis*** service, event storage base and platform data in real time. It uses the offial Redis docker image (https://hub.docker.com/_/redis).

<pre>
sentilo-redis:
    image: redis:${REDIS_VERSION}
    container_name: sentilo-redis
    command: ["redis-server", "/usr/local/etc/redis/redis.conf", "--appendonly", "yes"]
    volumes:
      - ./config/redis/redis.conf:/usr/local/etc/redis/redis.conf
    ports:
      - "6379:6379"
    expose:
      - 6379
    networks:
      - sentilo_network
</pre>

#### sentilo-mongodb

***MongoDB*** service, configuration storage and hierarchical structure of all platform components, credentials and element configurations. It uses the official MongoDB docker image (https://hub.docker.com/_/mongo).

<pre>
sentilo-mongodb:
    image: mongo:${MONGO_VERSION}
    container_name: sentilo-mongodb
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: sentilo
      MONGO_INITDB_DATABASE: sentilo
    volumes:
      - ./config/mongo/config/mongod.conf:/etc/mongod/mongod.conf
      - ./config/mongo/docker-entrypoint-initdb.d/:/docker-entrypoint-initdb.d/
    ports:
      - "27017:27017"
    expose:
      - 27017
    healthcheck:
      test: test $$(echo "rs.initiate().ok || rs.status().ok" | mongo -u admin -p 'sentilo' --quiet) -eq 1
      interval: 10s
      start_period: 30s
    command: [ "--replSet", "rs_sentilo", "--bind_ip_all" ]
    networks:
      - sentilo_network
</pre>

***NOTE:*** the heathcheck command is imperative to initiate the replica set correctly.

#### sentilo-platform-server

The **Sentilo Platform Server**, the PubSub API Rest core module. It uses the Sentilo official docker image (https://hub.docker.com/r/sentilo/sentilo-platform-server)

<pre>
sentilo-platform-server:
    image: sentilo-platform-server:${SENTILO_VERSION}
    container_name: sentilo-platform-server
    volumes:
      - ./conf/:/etc/sentilo/
      - ./logs/:/var/log/sentilo/
    ports:
      - "8081:8081"
      - "7081:7081"
    expose:
      - 8081
      - 7081
    links:
      - sentilo-redis
      - sentilo-mongodb
      - sentilo-catalog-web
    depends_on:
      - sentilo-catalog-web
    networks:
      - sentilo_network
</pre>

#### sentilo-agent-alert

The Sentilo Agent Alert, that manages internal & external platform alerts. It uses the Sentilo Agent Alert official docker image (https://hub.docker.com/r/sentilo/sentilo-agent-alert).

<pre>
sentilo-agent-alert:
    image: sentilo-agent-alert:${SENTILO_VERSION}
    container_name: sentilo-agent-alert
    volumes:
      - ./conf/:/etc/sentilo/
      - ./logs/:/var/log/sentilo/
    links:
      - sentilo-platform-server
    depends_on:
      - sentilo-platform-server
    networks:
      - sentilo_network
</pre>

#### sentilo-agent-location-updater

The Sentilo Agent Location Updater, that manages the platform components location. It uses the Sentilo Agent Location Updater official docker image (https://hub.docker.com/r/sentilo/sentilo-agent-location-updater).

<pre>
sentilo-agent-location-updater:
    image: sentilo-agent-location-updater:${SENTILO_VERSION}
    container_name: sentilo-agent-location-updater
    volumes:
      - ./conf/:/etc/sentilo/
      - ./logs/:/var/log/sentilo/
    links:
      - sentilo-platform-server
    depends_on:
      - sentilo-platform-server
    networks:
      - sentilo_network
</pre>

#### sentilo-catalog-web

The Sentilo Catalog Web Application, that enables you to administer, rule and monitor the Sentilo platform resources and activity. It uses the Sentilo Catalog Web Application official docker image (https://hub.docker.com/r/sentilo/sentilo-catalog-web).

<pre>
sentilo-catalog-web:
    image: sentilo-catalog-web:${SENTILO_VERSION}
    container_name: sentilo-catalog-web
    ports:
      - "8080:8080"
    expose:
      - 8080
    links:
      - sentilo-mongodb
      - sentilo-redis
    depends_on:
      - sentilo-mongodb
      - sentilo-redis
    volumes:
      - ./conf/:/etc/sentilo/
      - ./logs/:/var/log/sentilo/
    networks:
      - sentilo_network
</pre>

### Networks

In order to be able to communicate easily and efficiently each of the platform containers, a network has been created to which each of them will be connected, called `sentilo_network`.

<pre>
networks:
  sentilo_network:
    ipam:
      driver: default
</pre>

## Create and run the Sentilo 2.0.0 platform docker image

There are different shellscripts that allow us to perform the tasks of creating, starting and stopping the Sentilo services platform:

- `build_sentilo_docker_image.sh`: execute this shellscript to create each of the platform services. within a docker project called "Sentilo200" (it also creates the local `./log`directory where will appear all the platform logs)
- `start_sentilo_docker.sh`: execute this shellscript to start the platform services
- `stop_sentilo_docker.sh`:  execute this shellscript to stop the platform services

## Access the Sentilo platform

Once we have created and started all the services, and assuming that we have docker running on our local machine, we can access the platform in the following way (if the default port values have not been changed):

- Sentilo Catalog Web Application: http://locahost:8080/sentilo-catalog-web
    - user: admin
    - password: 1234
- Sentilo API Rest platform server: http://locahost:8081

## Further information

Please, visit: https://www.sentilo.io
