#!/bin/bash
set -euo pipefail

./scripts/install.sh
./scripts/update-users.sh developers emis-backend/researchers emis-backend/reviewers
./scripts/jobrunner.sh emis-backend
