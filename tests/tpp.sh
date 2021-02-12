#!/bin/bash
./tpp/manage.sh
# run again to check for idempotency
./tpp/manage.sh

# Some assertions
set -e
grep -q SimonDavy@OPENCORONA ~bloodearnest/.ssh/authorized_keys

