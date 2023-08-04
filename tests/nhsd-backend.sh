#!/bin/bash
set -euo pipefail

BACKEND_JUST=nhsd-backend ./scripts/bootstrap.sh

just manage
#run again to check for idempotency
just manage

systemctl status jobrunner


# check that jobrunner is running with jobrunner group
test "$(systemctl show --property Group --value jobrunner)" = "jobrunner"

