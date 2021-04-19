#!/bin/bash
set -euo pipefail
./tpp-backend/manage.sh
# run again to check for idempotency
./tpp-backend/manage.sh

# Some assertions
set -e
grep -q SimonDavy@OPENCORONA ~bloodearnest/.ssh/authorized_keys

