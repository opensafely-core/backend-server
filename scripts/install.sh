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
sed 's/^#.*//' core-packages.txt | xargs apt-get install -y
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


# system configurations

# disable broken-by-default rsync service
systemctl disable rsync

# copy our files
cp -a --no-preserve ownership etc/opensafely /etc/
chmod 0640 /etc/opensafely/*

ln -sf /etc/opensafely/profile /etc/profile.d/opensafely.sh
ln -sf /etc/opensafely/sudoers /etc/sudoers.d/opensafely
ln -sf /etc/opensafely/ssh.conf /etc/ssh/sshd_config.d/99-opensafely.conf

grep -q "^UMASK.*027" /etc/login.defs || sed -i 's/^UMASK.*$/UMASK 027/' /etc/login.defs

systemctl reload ssh
