#!/bin/bash

# Force recreate containers if already running.
docker compose -f /root/docker-compose.yml up --force-recreate -d

