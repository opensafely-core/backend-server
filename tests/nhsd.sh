#!/bin/bash
set -euo pipefail
./nhsd-backend/manage.sh
#run again to check for idempotency
./nhsd-backend/manage.sh

systemctl status jobrunner


# check that jobrunner is running with jobrunner group
test "$(systemctl show --property Group --value jobrunner)" = "jobrunner"

