#!/bin/bash
set -euo pipefail

./scripts/install.sh
./scripts/update-users.sh developers backends/emis/researchers backends/emis/reviewers
