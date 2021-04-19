#!/bin/bash
set -euo pipefail
# Test install scripts
./scripts/install.sh
# run again to test idempotency
./scripts/install.sh

