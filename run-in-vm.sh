#!/bin/bash
set -euo pipefail
name=${VMNAME:-backend-server}
test -x "$(command -v multipass)" || { echo "You need multipass installed to run this script: https://multipass.run"; exit 1; }

delete() {
    echo "Removing $name..."
    multipass delete --purge "$name" >/dev/null 2>&1 || true &
}


# always start clean
multipass delete --purge "$name" 2>/dev/null || true

multipass launch 20.04 --name "$name"
trap delete EXIT

# add this directory in VM as /host, with current user mapped to root
multipass mount "$PWD" "$name:/host" --uid-map "$(id -u):0"

# wait for first boot to finish
#multipass exec "$name" -- cloud-init status --wait || true

# run our command
multipass exec "$name"  -- sudo /usr/bin/env --chdir /host TEST=true SHELLOPTS=xtrace "$@"

echo "Running shell inside VM (will be deleted on exit)"
multipass exec "$name"  -- sudo /usr/bin/env --chdir /host TEST=true SHELLOPTS=xtrace bash


