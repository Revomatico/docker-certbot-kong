#!/bin/bash

# Test run the image is created by running bash in a temporary container

. common.sh

docker run -it \
    --rm \
    -e MAIN_DOMAIN=$MAIN_DOMAIN \
    -e EMAIL=$EMAIL \
    -e KONG_ADMIN=$KONG_ADMIN \
    -e API_USER=$API_USER \
    -e API_KEY=$API_KEY \
    --name $DOCKER_CONTAINER \
    $DOCKER_IMAGE \
    bash
