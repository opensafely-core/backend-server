#!/bin/bash
set -euo pipefail

# set DNS for RELEASE_HOST to 127.0.0.1
# shellcheck source=/dev/null
source /home/opensafely/config/load-env
HOSTNAME="$(echo "$RELEASE_HOST" | cut -d'/' -f3 | cut -d':' -f1)"
grep -q "$HOSTNAME" /etc/hosts || echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

curl --retry-all-errors --retry 5 --retry-delay 1 -vL --fail "$RELEASE_HOST" -o /tmp/airlock-homepage.html || curl -vL "$RELEASE_HOST"
grep "<title>Login | Airlock</title>" /tmp/airlock-homepage.html >/dev/null

# verify that the workspace mount is read-only
if docker exec airlock touch /workspaces/test 2>/dev/null; then
  echo "airlock:/workspaces unexpectedly writable"
  exit 1
fi

# verify the background uploaded process is running
if ! docker exec airlock pgrep --full run_file_uploader >/dev/null; then
  echo "Could not detect the background run_file_uploader process"
  echo "docker exec airlock ps aux"
  docker exec airlock ps aux
  exit 1
fi


service="$(docker exec airlock env | grep OTEL_SERVICE_NAME)"
if test "$service" != "OTEL_SERVICE_NAME=airlock-$BACKEND"; then
    echo "Misconfigured OTEL_SERVICE_NAME: $service"
    docker exec airlock env
    exit 1
fi
