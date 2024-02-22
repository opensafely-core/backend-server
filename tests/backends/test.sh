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
tout 5s systemctl status jobrunner


# hack to pull in ehrql for this job
/home/opensafely/jobrunner/code/scripts/update-docker-image.sh ehrql:v1

# run a job
cat << EOF | su - opensafely -c bash
set -a
for f in /home/opensafely/config/*.env; do
    . "\$f"
done
set +a
export PYTHONPATH=/home/opensafely/jobrunner/code:/home/opensafely/jobrunner/lib
python3 -m jobrunner.cli.add_job https://github.com/opensafely/research-template generate_dataset
EOF

script=$(mktemp)
cat << EOF > "$script"
until journalctl -u jobrunner | grep -q 'Completed successfully status=StatusCode.SUCCEEDED workspace=test action=generate_dataset'
do
    sleep 2
done
EOF

tout 60s bash "$script" || { journalctl -u jobrunner; exit 1; }

systemctl status collector || { journalctl -u collector; exit 1; }

# run airlock tests
./tests/check-airlock.sh
