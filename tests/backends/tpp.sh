#!/bin/bash
set -euo pipefail

./scripts/bootstrap.sh tpp

./tests/check-bootstrap.sh tpp

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
docker compose -f ~opensafely/jobrunner/docker-compose.yaml exec controller true || { docker compose -f ~opensafely/jobrunner/docker-compose.yaml logs; exit 1; }

# test collector service up
systemctl status collector || { journalctl -u collector --no-pager; exit 2; }

# run airlock tests
./tests/check-airlock.sh

msg="Wrong scheme for MS-SQL URL"
rc=0

# we need cohortextractor to run the vmp-mapping test
just -f ~opensafely/jobrunner/justfile update-docker-image cohortextractor


echo "We expect this to error in tests!"
systemctl start --now vmp-mapping || rc=$?

if ! journalctl -u vmp-mapping | grep -q 'Wrong scheme for MS-SQL URL'; then
    echo "vmp-mapping should exit with exit code 1: exited with $rc"
    echo "Expected error message not found: $msg"
    journalctl -u vmp-mapping
    exit 1
fi
