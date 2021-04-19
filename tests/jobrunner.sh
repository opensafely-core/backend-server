#!/bin/bash
set -euo pipefail
./scripts/install.sh
./scripts/jobrunner.sh tpp-backend

# check it is running
sleep 3 # let it have chance to start up
systemctl status jobrunner
