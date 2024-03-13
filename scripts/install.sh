#!/bin/bash
# Install/update all the groups and system level configuration.
set -euo pipefail

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
chmod 0755 /etc/opensafely/
chmod 0640 /etc/opensafely/*

ln -sf /etc/opensafely/profile /etc/profile.d/opensafely.sh
ln -sf /etc/opensafely/sudoers /etc/sudoers.d/opensafely
ln -sf /etc/opensafely/ssh.conf /etc/ssh/sshd_config.d/99-opensafely.conf

# create directory for selfsigned test certifcates
mkdir -p /usr/local/share/ca-certificates/opensafely

# clean up old files
rm -f /etc/opensafely/ssh-banner

# explicitly allow these things for user to rx
chmod 0755 /etc/opensafely/{banner,bashrc}

# add login banner
ln -sf /etc/opensafely/banner /etc/update-motd.d/00-opensafely-banner

# add our bashrc config
if ! grep -q "etc/opensafely/bashrc" /etc/bash.bashrc; then
    echo "test -f /etc/opensafely/bashrc && . /etc/opensafely/bashrc" >> /etc/bash.bashrc
fi

# reduce motd noise
chmod a-x /etc/update-motd.d/{10-help-text,50-motd-news,91-contract-ua-esm-status,91-release-upgrade}

grep -q "^UMASK.*027" /etc/login.defs || sed -i 's/^UMASK.*$/UMASK 027/' /etc/login.defs

# ensure shipped binaries (note: *not* just, as that fails as we're running it atm)
cp bin/otel-cli /usr/local/bin/
chmod a+rx /usr/local/bin

systemctl reload ssh

# disable cloud-init management of /etc/hosts
echo -e "manage_etc_hosts: false" > /etc/cloud/cloud.cfg.d/99-opensafely.cfg
# remove confusing banner in /etc/hosts if present
sed -i.bak -z "s/# Your system has configured 'manage_etc_hosts'.*cloud-config from user-data\n#\n//" /etc/hosts

# hardcode /etc/hosts entries so we don't need DNS
if grep -q "## start opensafely dns" /etc/hosts; then
    # -z use NULL for new line, enables multiline matching
    # first -e adds the current file content
    # second -e removes the old file content
    sed -z -e '/## start opensafely dns.*## end opensafely dns/r etc/opensafely/hosts' -e 's/## start opensafely dns.*## end opensafely dns//' -i.bak /etc/hosts
else
    echo "" >> /etc/hosts
    cat etc/opensafely/hosts >> /etc/hosts
fi
