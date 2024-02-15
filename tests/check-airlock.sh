#!/bin/bash
set -euo pipefail

# set DNS for RELEASE_HOST to 127.0.0.1
# shellcheck source=/dev/null
source /home/opensafely/config/load-env
HOSTNAME="$(echo "$RELEASE_HOST" | cut -d'/' -f3 | cut -d':' -f1)"
grep -q "$HOSTNAME" /etc/hosts || echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

# simple test of the running airlock
curl -s --fail "$RELEASE_HOST" -o /tmp/airlock-homepage.html
grep "<title>Airlock</title>" /tmp/airlock-homepage.html

# verify that the workspace mount is read-only
if docker exec airlock touch /workspaces/test; then
  echo "airlock:/workspaces unexpectedly writable"
  exit 1
fi
