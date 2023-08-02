#!/bin/bash
set -euo pipefail

./scripts/install.sh
./scripts/update-users.sh developers tpp-backend/researchers
./services/jobrunner/install.sh tpp-backend
./release-hatch/install.sh
./services/collector/install.sh
