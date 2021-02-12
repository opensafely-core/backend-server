#!/bin/bash
# Install/update all the base packages and groups and system level configuration.
set -euo pipefail

# packages
export DEBIAN_FRONTEND="noninteractive"
apt-get update
apt-get upgrade -y
sed 's/^#.*//' packages.txt | xargs apt-get install -y

# ensure groups
for group in developers researchers reviewers; do
    if ! getent group $group > /dev/null; then
        echo "Adding group $group"
        groupadd $group
    fi
done
