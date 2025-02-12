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

just manage
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

just -f ~opensafely/jobrunner/justfile update-docker-image ehrql:v1
just -f ~opensafely/jobrunner/justfile add-job https://github.com/opensafely/research-template generate_dataset

script=$(mktemp)
cat << EOF > "$script"
until journalctl -t jobrunner -n 10 | grep -q 'Completed successfully status=StatusCode.SUCCEEDED workspace=test action=generate_dataset'
do
    sleep 2
done
EOF

tout 60s bash "$script" || { journalctl -t jobrunner; exit 1; }

systemctl status --no-pager collector || { journalctl -u collector; exit 1; }

# run airlock tests
./tests/check-airlock.sh
