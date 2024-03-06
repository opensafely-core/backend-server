#!/bin/bash
set -euo pipefail

DIR=~opensafely/airlock
OVERRIDE_FILE="backends/$BACKEND/airlock.override.yaml"
MEDIUM_PRIVACY_STORAGE_BASE=/srv/medium_privacy

mkdir -p $DIR
cp -a ./services/airlock/* "$DIR"

if test -f "$OVERRIDE_FILE"; then
    cp "$OVERRIDE_FILE" "$DIR/docker-compose.override.yaml"
fi

if test "${TEST:-}" = "true"; then
    just -f $DIR/justfile create-test-certificates
fi

chown -R opensafely:opensafely "$DIR"
chmod -R go-rwx "$DIR"

# give the airlock user read access to the certs
chown -R opensafely:airlock "$DIR/certs"
chmod -R g+rx "$DIR/certs"

# airlock/workdir will be created automatically by docker-compose when it
# attempts to mount it, but it will have root ownership by default &
# the airlock user needs to own it.
AIRLOCK_WORKDIR=~airlock/workdir
mkdir -p "$AIRLOCK_WORKDIR"
chown -R airlock:airlock "$AIRLOCK_WORKDIR"
chmod -R go-rwx "$AIRLOCK_WORKDIR"

REQUESTS_DIR="$MEDIUM_PRIVACY_STORAGE_BASE/requests"
mkdir -p "$REQUESTS_DIR"
find "$REQUESTS_DIR" -type f -exec chmod 640 {} +


systemctl enable "$DIR/airlock.service"
systemctl enable "$DIR/airlock.timer"
systemctl start airlock.timer
systemctl start airlock.service || { journalctl -u airlock.service; exit 1; }
