#!/bin/bash
set -euo pipefail

./scripts/install.sh
./scripts/update-users.sh developers
./services/jobrunner/install.sh test-backend
./release-hatch/install.sh
./services/osrelease/install.sh
./services/collector/install.sh
