#!/bin/bash

# Common script used by build.sh and run.sh to define variables and stay DRY
DOCKER_CONTAINER='certbot-kong'
DOCKER_IMAGE="local/$DOCKER_CONTAINER:1.0"

MAIN_DOMAIN=mydomain.com
EMAIL=office@$MAIN_DOMAIN
# We assume Kong runs in Kubernetes
KONG_ADMIN='http://kong-admin.kong:8001'
