#!/bin/bash
set -euo pipefail

DIR=~opensafely/airlock
OVERRIDE_FILE="backends/$BACKEND/airlock.override.yaml"

# shellcheck source=/dev/null
. scripts/load-env

mkdir -p $DIR
cp -a ./services/airlock/* "$DIR"
# ensure certs directory exists for certificate refreshes
mkdir -p "$DIR/certs"

if test -f "$OVERRIDE_FILE"; then
    cp "$OVERRIDE_FILE" "$DIR/docker-compose.override.yaml"
fi

if test "${TEST:-}" = "true"; then
    just -f $DIR/justfile create-test-certificates
fi

# airlock/workdir will be created automatically by docker compose when it
# attempts to mount it, but it will have root ownership by default &
# the opensafely user needs to own it.
mkdir -p $DIR/workdir

chown -R opensafely:opensafely "$DIR"
chmod -R go-rwx "$DIR"

REQUESTS_DIR="$MEDIUM_PRIVACY_STORAGE_BASE/requests"
mkdir -p "$REQUESTS_DIR"
find "$REQUESTS_DIR" -type f -exec chmod 640 {} +


echo "OTEL_SERVICE_NAME=airlock-$BACKEND" > $DIR/.env

systemctl enable "$DIR/airlock.service"
systemctl enable "$DIR/airlock.timer"
systemctl start airlock.timer
systemctl start airlock.service || { journalctl -u airlock.service; exit 1; }
