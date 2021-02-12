#!/bin/bash
set -euo pipefail

./scripts/install.sh
./scripts/update-users.sh developers tpp/researchers
