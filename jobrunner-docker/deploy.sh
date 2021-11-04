#!/bin/bash
set -euo pipefail

# start the docker container
DIR=~jobrunner/job-runner

# set up ssh keys for docker container
make ssh/id_ed25519.authorized

echo "Pulling image"
# TODO: is this name job-runner or jobrunner?
docker-compose --no-ansi -f $DIR/docker-compose.yaml pull --quiet job-runner
docker-compose --no-ansi -f $DIR/docker-compose.yaml up --detach job-runner



