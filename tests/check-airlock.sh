#!/bin/bash
set -euo pipefail

# set DNS for RELEASE_HOST to 127.0.0.1
# shellcheck source=/dev/null
source /home/opensafely/config/load-env
HOSTNAME="$(echo "$RELEASE_HOST" | cut -d'/' -f3 | cut -d':' -f1)"
grep -q "$HOSTNAME" /etc/hosts || echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

# simple test of the running airlock
curl -sL --fail "$RELEASE_HOST" -o /tmp/airlock-homepage.html
grep "<title>Login | Airlock</title>" /tmp/airlock-homepage.html

# verify that the workspace mount is read-only
if docker exec airlock touch /workspaces/test; then
  echo "airlock:/workspaces unexpectedly writable"
  exit 1
fi

# verify the background uploaded process is running
if ! docker exec airlock pgrep --full run_file_uploader; then
  echo "Could not detect the background run_file_uploader process"
  echo "docker exec airlock ps aux"
  docker exec airlock ps aux
  exit 1
fi
