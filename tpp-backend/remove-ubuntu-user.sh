#!/bin/bash
set -euo pipefail

# lock the ubuntu user
usermod -L ubuntu

# expire the ubuntu user
chage -E0 ubuntu

# remove any ssh config
rm -rf ~ubuntu/.ssh

# Remove the host ssh keys from the image.
# We've configued new keys to be generated on next boot.
rm /etc/ssh/ssh_host_*_key*
