#!/bin/bash
set -euo pipefail

./scripts/install.sh
./scripts/update-users.sh developers
./jobrunner-docker/install.sh test-backend
./release-hatch/install.sh
