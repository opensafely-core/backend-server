#!/bin/bash
set -euo pipefail
./test-backend/manage.sh
# run again to check for idempotency
./test-backend/manage.sh



