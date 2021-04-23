#!/bin/bash
# Install/update all the base packages and groups and system level configuration.
set -euo pipefail

# packages
export DEBIAN_FRONTEND="noninteractive"
# running this set -u sometimes causes issues with packaging scripts, it seems
set +u
sed 's/^#.*//' purge-packages.txt | xargs apt-get purge -y
apt-get update
apt-get upgrade -y
sed 's/^#.*//' packages.txt | xargs apt-get install -y
apt-get autoremove -y

set -u

# ensure groups
for group in developers researchers reviewers; do
    if ! getent group $group > /dev/null; then
        echo "Adding group $group"
        groupadd $group
    fi
done

cp etc/developers-sudo-access /etc/sudoers.d
