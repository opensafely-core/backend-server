#!/bin/bash
# Install/update all the base packages and groups and system level configuration.
set -euo pipefail

# packages
INSTALL_PACKAGES=${INSTALL_PACKAGES:-true}
# we can't install packages in EMIS atm, so allow skipping that
if test "$INSTALL_PACKAGES" = "true"; then
    # running this set -u sometimes causes issues with packaging scripts, it seems
    set +u
    sed 's/^#.*//' purge-packages.txt | xargs apt-get purge -y
    apt-get update
    apt-get upgrade -y
    sed 's/^#.*//' core-packages.txt | xargs apt-get install -y
    sed 's/^#.*//' packages.txt | xargs apt-get install -y
    apt-get autoremove -y
    set -u
fi

ensure_group() {
    local name=$1
    shift;
    if getent group "$name" > /dev/null; then
        groupmod "$@" "$name"
    else
        groupadd "$@" "$name"
    fi
}

# group that can manage services
ensure_group developers
ensure_group researchers
# group that can view output files in /srv/{high,medium}_privacy/
# we use hardcoded gid to match docker image gids
ensure_group reviewers --gid 10010

# system config
#
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
