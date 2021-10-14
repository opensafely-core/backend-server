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

./test-backend/manage.sh
# run again to check for idempotency
./test-backend/manage.sh

# test user setup
test "$(id -u jobrunner)" == "10000"
test "$(id -g jobrunner)" == "10000"

# test that the updater runs successfully
script=$(mktemp)
cat << EOF > "$script"
until journalctl | grep -q "job-runner is up-to-date"
do
    sleep 2
done
EOF

tout 30s bash "$script" || { journalctl; exit 1; }

# run tests/jobrunner-docker.sh inside the jobrunner docker container
# /srv/jobrunner/ is mounted into the docker container
cp tests/jobrunner-docker.sh /srv/jobrunner/
docker-compose -f ~jobrunner/job-runner/docker-compose.yaml exec -T job-runner /app/workdir/jobrunner-docker.sh
journalctl

docker-compose -f ~jobrunner/job-runner/docker-compose.yaml logs job-runner

exit 1


# run release-hatch tests
./tests/check-release-hatch
