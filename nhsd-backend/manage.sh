#!/bin/bash
set -euo pipefail

# install/update the core requirements
apt-get update
sed 's/^#.*//' core-packages.txt | xargs apt-get install -y

# setup job runner, but do not use the default reviewers group, as it doesn't
# exist in NSHD land.
export REVIEWERS_GROUP=jobrunner
./services/jobrunner/install.sh nhsd-backend

