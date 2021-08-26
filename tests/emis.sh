#!/bin/bash
set -euo pipefail
./emis-backend/manage.sh
#run again to check for idempotency
./emis-backend/manage.sh

# Some assertions
grep -q SimonDavy@OPENCORONA ~bloodearnest/.ssh/authorized_keys

# run hatch tests
./tests/check-hatch
