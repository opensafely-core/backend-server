#!/bin/bash
set -euo pipefail

# start the docker container
DIR=~jobrunner/release-hatch
echo "Pulling image"
docker-compose --no-ansi -f $DIR/docker-compose.yaml pull --quiet release-hatch
echo "Bringing up image"
docker-compose --no-ansi -f $DIR/docker-compose.yaml up --detach release-hatch
