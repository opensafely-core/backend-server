#!/bin/bash
set -euo pipefail

./scripts/install.sh
./scripts/update-users.sh developers
./scripts/jobrunner.sh test-backend
./hatch/install.sh
