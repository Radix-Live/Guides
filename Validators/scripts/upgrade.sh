#!/bin/bash

export DISABLE_VERSION_CHECK="true"
docker compose -f /root/docker-compose.yml pull

./stop-validator.sh keep-key

babylonnode docker start
