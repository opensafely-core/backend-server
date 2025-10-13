#!/bin/bash
set -euo pipefail

./scripts/bootstrap.sh ted

./tests/check-bootstrap.sh ted

./tests/stub-controller.sh ted

just manage

# jobrunner.service runs `just deploy` which will not start jobrunner if it not
# already running, so manually start it here
just -f ~opensafely/jobrunner/justfile start

# run again to check for idempotency
just manage

# override developers field to be able to disable user
# user must exist, using test author :shrug:
developers=/dev/null just disable-user bloodearnest

if test -f ~bloodearnest/.ssh; then
    echo "bloodearnest .ssh/authorized_keys not deleted"
    exit 1
fi

if groups bloodearnest | grep -q developers; then
    echo "bloodearnest still in developers group"
    exit 1
fi

if ! passwd -S bloodearnest | grep -q "bloodearnest L"; then
    echo "bloodearnest password not locked"
    exit 1
fi

# test user setup
test "$(id -u opensafely)" == "10000"
test "$(id -g opensafely)" == "10000"

./tests/check-agent.sh
./tests/check-collector.sh
./tests/check-airlock.sh

# Test the upgrade command completes without error (we have to use Y to accept
# the upgrade because declining causes a non-zero exit)
echo 'Y' | just apt-upgrade
