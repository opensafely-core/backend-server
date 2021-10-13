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
# TODO: what is the return code from this, for a successful timer run?
# TODO: do this for release-hatch too
# tout 5s systemctl status job-runner || job_runner_timer_code=$?
#
# if test "$job_runner_timer_code" != "3"; then
#     echo "job-runner auto-update failed"
# fi

# run tests/jobrunner-docker.sh inside the jobrunner docker container
# /srv/jobrunner/ is mounted into the docker container
cp tests/jobrunner-docker.sh /srv/jobrunner/

docker-compose -f ~jobrunner/job-runner/docker-compose.yaml logs job-runner
docker-compose -f ~jobrunner/job-runner/docker-compose.yaml exec -T job-runner pwd
docker-compose -f ~jobrunner/job-runner/docker-compose.yaml exec -T job-runner ls -lh 
docker-compose -f ~jobrunner/job-runner/docker-compose.yaml exec -T job-runner ls -lh /app/workdir/
docker-compose -f ~jobrunner/job-runner/docker-compose.yaml exec -T job-runner ls -lh /app/workdir/jobrunner-docker.sh
docker-compose -f ~jobrunner/job-runner/docker-compose.yaml exec -T job-runner /app/workdir/jobrunner-docker.sh
exit 1


# run release-hatch tests
./tests/check-release-hatch
