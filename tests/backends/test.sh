#!/bin/bash
set -euo pipefail

tout() {
	local duration=$1
	shift

	code=0
    timeout --foreground "$duration" "$@" || code=$?

	if test "$code" == "124"; then
		echo "Timeout waiting for: $*"
	fi
	return $code
}

./scripts/bootstrap.sh test

./tests/check-bootstrap.sh test

./tests/stub-controller.sh test

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

# test service is up

script=$(mktemp)
cat << EOF > "$script"
until journalctl -t agent -n 100 | grep -qF 'agent.main loop started'
do
    sleep 2
done
EOF

tout 60s bash "$script" || { journalctl -t agent; exit 1; }

./tests/check-collector.sh test

# run airlock tests
./tests/check-airlock.sh

# Test the upgrade command completes without error (we have to use Y to accept
# the upgrade because declining causes a non-zero exit)
echo 'Y' | just apt-upgrade
