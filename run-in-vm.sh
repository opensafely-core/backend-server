#!/bin/bash
set -x -euo pipefail
name=${VMNAME:-backend-server}
test -x "$(command -v multipass)" || { echo "You need multipass installed to run this script: https://multipass.run"; exit 1; }

delete() {
    echo "Removing $name..."
    multipass delete --purge "$name" >/dev/null 2>&1 || true
}


# always start clean
multipass delete --purge "$name" 2>/dev/null || true

multipass launch 20.04 --name "$name"
test -z "${KEEP:-}" && trap delete EXIT

# add this directory in VM as /host
multipass mount "$PWD" "$name:/host" 

# wait for first boot to finish
#multipass exec "$name" -- cloud-init status --wait || true

# run our command 
# note: via bash, as so we don't rely on executable bits 
multipass exec "$name" -- sudo env --chdir //host TEST=true SHELLOPTS=xtrace bash "$@"

if test -z "${KEEP:-}"; then
    echo "Running shell inside VM (will be deleted on exit)"
    multipass exec "$name" -- sudo env --chdir //host TEST=true bash
else
    exit 0
fi
