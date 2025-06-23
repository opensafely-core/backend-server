#!/bin/bash
set -euo pipefail

./scripts/bootstrap.sh tpp

./tests/check-bootstrap.sh tpp

# set up stub controller now, so that the agent will start ok
./tests/stub-controller.sh tpp

just manage

# jobrunner.service runs `just deploy` which will not start jobrunner if it not
# already running, so manually start it here
just -f ~opensafely/jobrunner/justfile start

# run again to check for idempotency
just manage

# test for ssh keys
grep -q SimonDavy@OPENCORONA ~bloodearnest/.ssh/authorized_keys

sleep 3

# test jobrunner service up
docker compose -f ~opensafely/jobrunner/docker-compose.yaml exec agent true || { docker compose -f ~opensafely/jobrunner/docker-compose.yaml logs; exit 1; }

# test collector service up
./tests/check-collector.sh tpp

# run airlock tests
./tests/check-airlock.sh
