#!/bin/bash
set -euo pipefail
# clean an image ready for exporting

apt-get clean
apt-get autoremove

# remove any preinstalled and seeded snap to save some space
snap list lxd && snap remove lxd
snap list core18 && snap remove core18
rm -rf /var/lib/snapd/seed/*

if test "${COPY_CLOUD_INIT:-}" = "true"; then
    # If specified, copy custom cloud-init into the base image
    # Note: if we do this, we can't specify custom user data at
    # EC2 instance launch.
    #
    # run our custom cloud-init config at next boot
    # its main job is to re-generate ssh host keys
    mkdir -p /var/lib/cloud/seed/nocloud-net

    cp -a "$CLOUD_INIT_SRC_DIR"/* /var/lib/cloud/seed/nocloud-net
fi

# cloud init will now run on next boot
cloud-init clean --logs
