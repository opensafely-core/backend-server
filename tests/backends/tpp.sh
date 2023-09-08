#!/bin/bash
set -euo pipefail

./scripts/bootstrap.sh tpp

./tests/check-bootstrap.sh tpp

just manage
# run again to check for idempotency
just manage

# test for ssh keys
grep -q SimonDavy@OPENCORONA ~bloodearnest/.ssh/authorized_keys

sleep 3

# test jobrunner service up
systemctl status jobrunner || { journalctl -u jobrunner; exit 1; }

# test collector service up
systemctl status collector || { journalctl -u collector; exit 2; }

# run release-hatch tests
./tests/check-release-hatch.sh
