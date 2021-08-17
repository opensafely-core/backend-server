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

# test service is up
tout 5s systemctl status jobrunner

# hack to pull in the cohortextactor for this job
/srv/jobrunner/code/scripts/update-docker-image.sh cohortextractor

# run a job
echo "
export PYTHONPATH=/srv/jobrunner/code:/srv/jobrunner/lib
python3 -m jobrunner.add_job https://github.com/opensafely/research-template generate_study_population
" | su - jobrunner -c bash

script=$(mktemp)
cat << EOF > "$script"
until journalctl -u jobrunner | grep -q 'Completed successfully project=research-template action=generate_study_population'
do
    sleep 2
done
EOF

tout 30s bash "$script" || { journalctl -u jobrunner; exit 1; }
