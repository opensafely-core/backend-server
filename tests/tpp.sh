#!/bin/bash
set -euo pipefail
./tpp-backend/manage.sh
# run again to check for idempotency
./tpp-backend/manage.sh

grep -q SimonDavy@OPENCORONA ~bloodearnest/.ssh/authorized_keys

# run hatch tests
./tests/check-hatch
