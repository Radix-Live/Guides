#!/bin/bash

export DISABLE_VERSION_CHECK="true"
#  pull the new versions of the docker images
docker pull radixdlt/radixdlt-nginx:1.2.2
docker pull radixdlt/radixdlt-core:1.2.2

./stop-validator.sh keep-key
./node-start.sh
