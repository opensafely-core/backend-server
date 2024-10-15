#!/bin/bash
set -euo pipefail
name=${1-backend-server-test}

BACKEND_SERVER_PATH=$(dirname "${BASH_SOURCE[0]}")/../

lxc image delete "$name" || true
lxc delete -f "$name" || true
lxc launch ubuntu:22.04 "$name" --quiet -c security.nesting=true
lxc exec "$name" -- cloud-init status --wait

# install stuff
sed 's/^#.*//' "$BACKEND_SERVER_PATH"/purge-packages.txt | lxc exec "$name" -- xargs apt-get purge -y
lxc exec "$name" -- apt-get autoremove --yes
lxc exec "$name" -- apt-get update
lxc exec "$name" -- apt-get upgrade --yes
sed 's/^#.*//' "$BACKEND_SERVER_PATH"/core-packages.txt | lxc exec "$name" -- xargs apt-get install --no-install-recommends -y
sed 's/^#.*//' "$BACKEND_SERVER_PATH"/packages.txt | lxc exec "$name" -- xargs apt-get --no-install-recommends install -y

# preload ehrql:v1
#lxc exec "$name" -- docker pull ghcr.io/opensafely-core/ehrql:v1

lxc stop "$name"
time lxc publish --quiet "$name" --alias "$name"
# GHA version of lxd doesn't have this, so don't error
lxc image set-property "$name" description "Test image for backend-server project" || true
lxc delete "$name"
