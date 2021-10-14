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

# TODO: does this already contain cohortextractor?
# hack to pull in the cohortextactor for this job
# /app/scripts/update-docker-image.sh cohortextractor

# run a job
# TODO: /app/lib may be wrong
export PYTHONPATH=/app:/app/lib
python3 -m jobrunner.cli.add_job https://github.com/opensafely/research-template generate_study_population

script=$(mktemp)
cat << EOF > "$script"
until journalctl -u appuser | grep -q 'Completed successfully project=research-template action=generate_study_population'
do
    sleep 2
done
EOF

# tout 30s bash "$script" || { journalctl -u appuser; exit 1; }