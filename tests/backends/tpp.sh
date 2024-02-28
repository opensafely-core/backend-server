#!/bin/bash
set -euo pipefail

./scripts/bootstrap.sh tpp

./tests/check-bootstrap.sh tpp

just manage
# run again to check for idempotency
# just manage

# test for ssh keys
grep -q SimonDavy@OPENCORONA ~bloodearnest/.ssh/authorized_keys

sleep 3

# test jobrunner service up
systemctl status jobrunner || { journalctl -u jobrunner --no-pager; exit 1; }

# test collector service up
systemctl status collector || { journalctl -u collector --no-pager; exit 2; }

# run airlock tests
./tests/check-airlock.sh

msg="Wrong scheme for MS-SQL URL"
rc=0

/home/opensafely/jobrunner/code/scripts/update-docker-image.sh cohortextractor

echo "We expect this to error in tests!"
systemctl start --now vmp-mapping || rc=$?

if ! journalctl -u vmp-mapping | grep -q 'Wrong scheme for MS-SQL URL'; then
    echo "vmp-mapping should exit with exit code 1: exited with $rc"
    echo "Expected error message not found: $msg"
    journalctl -u vmp-mapping
    exit 1
fi

