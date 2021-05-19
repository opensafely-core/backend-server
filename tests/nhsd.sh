#!/bin/bash
set -euo pipefail
./nhsd-backend/manage.sh
#run again to check for idempotency
./nhsd-backend/manage.sh

systemctl status jobrunner
