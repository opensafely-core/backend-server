#!/bin/bash
set -euo pipefail

# install/update the core requirements
apt-get update
sed 's/^#.*//' core-packages.txt | xargs apt-get install -y

# setup job runner
./scripts/jobrunner.sh nhsd-backend

