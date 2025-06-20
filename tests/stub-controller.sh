#!/bin/bash
set -euo pipefail

backend=$1
# must match what's in tests/config.env
controller_port=8000
controller_tmpdir=/tmp/controller
mkdir -p "$controller_tmpdir/$backend/tasks"
echo '{"tasks": []}' > "$controller_tmpdir/$backend/tasks/index.html"

python3 -m http.server -d "$controller_tmpdir" "$controller_port" > $controller_tmpdir/controller.log 2>&1 &
