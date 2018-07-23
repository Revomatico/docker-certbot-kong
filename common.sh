#!/bin/bash

# Common script used by build.sh and run.sh to define variables and stay DRY
DOCKER_CONTAINER='certbot-kong'
DOCKER_IMAGE="local/$DOCKER_CONTAINER:0.2"

# Either uncomment this or manually set in the env. If running the container in Kubernetes, these can be set via secrets or configs.
#MAIN_DOMAIN=mydomain.com
#EMAIL=office@$MAIN_DOMAIN
#API_USER=username
#API_KEY=123apikey

# We assume Kong runs in Kubernetes
KONG_ADMIN='http://kong-admin.kong:8001'
