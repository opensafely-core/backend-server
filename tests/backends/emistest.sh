#!/bin/bash
set -euo pipefail

./scripts/bootstrap.sh emisv2

./tests/check-bootstrap.sh emisv2

# run the emis-only install-aws script
./backends/emisv2/scripts/install_aws_cli.sh

# set up stub controller now, so that the agent will start ok
./tests/stub-controller.sh emisv2

just manage

# jobrunner.service runs `just deploy` which will not start jobrunner if it not
# already running, so manually start it here
just -f ~opensafely/jobrunner/justfile start

# run again to check for idempotency
just manage

# test for ssh keys
grep -q SimonDavy@OPENCORONA ~bloodearnest/.ssh/authorized_keys

sleep 3

./tests/check-agent.sh
./tests/check-collector.sh
./tests/check-airlock.sh
