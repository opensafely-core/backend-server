#!/bin/bash
set -euo pipefail
./test-backend/manage.sh
# run again to check for idempotency
./test-backend/manage.sh

# test service is up
timeout 5s systemctl status jobrunner

# run a job
echo "
export PYTHONPATH=/srv/jobrunner/code:/srv/jobrunner/lib
python3 -m jobrunner.add_job https://github.com/opensafely/research-template generate_study_population
" | su - jobrunner -c bash


code=0
cat << EOF | timeout 20s bash || code=$?
until journalctl -u jobrunner | grep -q 'Completed successfully project=research-template action=generate_study_population'
do
    sleep 2
done
EOF

if test "$code" == "124"; then
    echo "Timeout waiting for job to complete"
fi

exit $code

