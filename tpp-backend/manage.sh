#!/bin/bash
set -euo pipefail

./scripts/install.sh
./scripts/update-users.sh developers tpp-backend/researchers
./scripts/jobrunner.sh tpp-backend
./release-hatch/install.sh
./services/collector/install.sh
