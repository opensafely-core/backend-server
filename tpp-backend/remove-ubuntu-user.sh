#!/bin/bash
set -euo pipefail

# lock the ubuntu user
usermod -L ubuntu

# expire the ubuntu user
chage -E0 ubuntu

# remove any ssh config
rm -rf ~ubuntu/.ssh

# remove the host ssh keys, we will no longer be able to ssh in after this
rm /etc/ssh/ssh_host_*_key*
