#!/bin/bash

export DISABLE_VERSION_CHECK="true"
radixnode docker stop -f radix-fullnode-compose.yml

./node-start.sh
