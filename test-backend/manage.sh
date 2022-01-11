#!/bin/bash
set -euo pipefail

./scripts/install.sh
./scripts/update-users.sh developers
./scripts/jobrunner.sh test-backend
./release-hatch/install.sh
./osrelease/install.sh
