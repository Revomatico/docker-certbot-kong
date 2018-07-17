#!/bin/bash

# Test if the image is created by running bash in a temporary container

. common.sh

docker run -it \
    --rm \
    -e MAIN_DOMAIN=$MAIN_DOMAIN \
    -e EMAIL=$EMAIL \
    -e KONG_ADMIN=$KONG_ADMIN \
    --name $DOCKER_CONTAINER \
    $DOCKER_IMAGE \
    bash
