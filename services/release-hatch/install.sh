#!/bin/bash
set -euo pipefail

DIR=~opensafely/release-hatch

mkdir -p $DIR
cp -a ./services/release-hatch/* "$DIR"

if test "${TEST:-}" = "true"; then
    just -f $DIR/justfile create-test-certificates
fi

chown -R opensafely:opensafely "$DIR"
chmod -R go-rwx "$DIR"

systemctl enable "$DIR/release-hatch.service"
systemctl enable "$DIR/release-hatch.timer"
systemctl start release-hatch.timer
systemctl start release-hatch.service || { journalctl -u release-hatch.service; exit 1; }
