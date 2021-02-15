#!/bin/bash
./emis-backend/manage.sh
#run again to check for idempotency
./emis-backend/manage.sh

# Some assertions
set -e
grep -q SimonDavy@OPENCORONA ~bloodearnest/.ssh/authorized_keys
