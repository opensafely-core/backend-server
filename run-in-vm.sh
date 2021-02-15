#!/bin/bash
set -euo pipefail
name=${VMNAME:-backend-server}

# TODO use multipass instead for x-platform support? 

delete() {
    echo "Removing $name..."
    lxc delete -f "$name" >/dev/null 2>&1 &
}


# always start clean
lxc delete -f "$name" 2>/dev/null || true

# launch temporary container, and map current $USER uid to root on the container
lxc launch --ephemeral ubuntu:20.04 -c raw.idmap="both $(id -u) 0" "$name"
trap delete EXIT

# add this directory in host as /host
lxc config device add "$name" cwd disk source="$PWD" path=/host

# allow docker to run inside container
lxc config set "$name" security.nesting true

# wait for first boot to finish
lxc exec "$name" -- cloud-init status --wait || true

# run our command
lxc exec "$name" --cwd /host --env TEST=true --env SHELLOPTS=xtrace -- "$@"

echo "Running shell inside VM (will be deleted on exit)"
lxc exec --cwd /host --env TEST=true "$name" -- bash


