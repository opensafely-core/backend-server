#!/bin/bash
set -euo pipefail

./scripts/install.sh
./scripts/update-users.sh developers emis/researchers emis/reviewers
