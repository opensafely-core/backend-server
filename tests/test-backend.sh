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

./scripts/bootstrap.sh test-backend

just manage
# run again to check for idempotency
just manage

# test user setup
test "$(id -u jobrunner)" == "10000"
test "$(id -g jobrunner)" == "10000"

# test service is up
tout 5s systemctl status jobrunner

# hack to pull in the cohortextactor for this job
/srv/jobrunner/code/scripts/update-docker-image.sh cohortextractor

# run a job
echo "
export PYTHONPATH=/srv/jobrunner/code:/srv/jobrunner/lib
python3 -m jobrunner.cli.add_job https://github.com/opensafely/research-template generate_study_population
" | su - jobrunner -c bash

script=$(mktemp)
cat << EOF > "$script"
until journalctl -u jobrunner | grep -q 'Completed successfully status=StatusCode.SUCCEEDED workspace=test action=generate_study_population'
do
    sleep 2
done
EOF

tout 60s bash "$script" || { journalctl -u jobrunner; exit 1; }

systemctl status collector || { journalctl -u collector; exit 1; }

# run release-hatch tests
./tests/check-release-hatch.sh
