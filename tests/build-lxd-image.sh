#!/bin/bash
set -euo pipefail
CLOUD_INIT_TIMEOUT=${CLOUD_INIT_TIMEOUT:-300}

wait_for_cloud_init() {
    local instance=$1
    echo -n "Waiting for cloud-init to finish"
    if ! lxc exec "$instance" -- timeout "$CLOUD_INIT_TIMEOUT" cloud-init status --wait; then
        echo "cloud-init did not finish within ${CLOUD_INIT_TIMEOUT}s for $instance; continuing" >&2
        lxc exec "$instance" -- cloud-init status --long || true
    fi
}
name=${1-backend-server-test}

BACKEND_SERVER_PATH=$(dirname "${BASH_SOURCE[0]}")/../

lxc_env() {
    lxc exec "$name" --env DEBIAN_FRONTEND=noninteractive --env NEEDRESTART_MODE=a -- "$@"
}

echo -n "Removing any previous images..."
lxc image delete "$name" 2>/dev/null || true
lxc delete -f "$name" 2>/dev/null || true
echo "done."
echo -n "Creating lxc vm..."
lxc launch ubuntu:22.04 "$name" --quiet -c security.nesting=true
echo "done."
wait_for_cloud_init "$name"

# install stuff
sed 's/^#.*//' "$BACKEND_SERVER_PATH"/purge-packages.txt \
    | lxc_env xargs apt-get purge -y
lxc_env apt-get autoremove --yes
lxc_env apt-get update
lxc_env apt-get upgrade --yes
sed 's/^#.*//' "$BACKEND_SERVER_PATH"/core-packages.txt \
    | lxc_env xargs apt-get install --no-install-recommends -y
sed 's/^#.*//' "$BACKEND_SERVER_PATH"/packages.txt \
    | lxc_env xargs apt-get install --no-install-recommends -y

# preload ehrql:v1
#lxc exec "$name" -- docker pull ghcr.io/opensafely-core/ehrql:v1

lxc stop "$name"
time lxc publish --quiet "$name" --alias "$name"
# GHA version of lxd doesn't have this, so don't error
lxc image set-property "$name" description "Test image for backend-server project" || true
lxc delete "$name"
