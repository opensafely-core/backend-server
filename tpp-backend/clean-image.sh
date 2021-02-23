#!/bin/bash
set -euo pipefail
# clean an image ready for exporting

apt-get clean
apt-get autoremove

# remove any preinstalled and seeded snap to save some space
snap list lxd && snap remove lxd
snap list core18 && snap remove core18
rm -rf /var/lib/snapd/seed/*

# run our custom cloud-init config at next boot
# it's main job is to re-generate ssh host keys
mkdir -p /var/lib/cloud/seed/nocloud-net
cp ./cloud-init/* /var/lib/cloud/seed/nocloud-net
# cloud init will now run on next boot
cloud-init clean --logs
