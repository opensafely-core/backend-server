#!/bin/bash
set -euo pipefail

# Set up the job-runner service
SRC_DIR=services/jobrunner
BACKEND_SRC_DIR=backends/$1
HOME_DIR=/home/opensafely
TARGET_DIR=$HOME_DIR/jobrunner
REVIEWERS_GROUP="${REVIEWERS_GROUP:-reviewers}"

# set default file creation permission for this script be 640 for files and 750
# for directories
umask 027

# load config
set -a
# shellcheck disable=SC1090
for f in "$HOME_DIR"/config/*.env; do
    # shellcheck disable=1090
    . "$f"
done
set +a;

# set up jobrunner

mkdir -p $TARGET_DIR
# ensure we have a checkout of job-runner and dependencies
test -d $TARGET_DIR/code || git clone https://github-proxy.opensafely.org/opensafely-core/job-runner $TARGET_DIR/code
test -d $TARGET_DIR/lib || git clone https://github-proxy.opensafely.org/opensafely-core/job-runner-dependencies $TARGET_DIR/lib

# service configuration
SECRET_DIR=$HOME_DIR/secret
mkdir -p $SECRET_DIR
chmod 0700 $SECRET_DIR
find $SECRET_DIR -type f -exec chmod 0600 {} \;

BIN_DIR=$HOME_DIR/bin
mkdir -p $BIN_DIR

cp $SRC_DIR/bin/* $BIN_DIR/
cp bin/lsjobs $BIN_DIR/
cp $SRC_DIR/sbin/* /usr/local/sbin

# setup output directories
for output_dir in "$HIGH_PRIVACY_STORAGE_BASE" "$MEDIUM_PRIVACY_STORAGE_BASE"; do
    mkdir -p "$output_dir/workspaces"
    # only group read access, no world access
    find "$output_dir" -type f -exec chmod 640 {} +
done
chown -R opensafely:opensafely "$HIGH_PRIVACY_STORAGE_BASE"
chown -R "opensafely:$REVIEWERS_GROUP" "$MEDIUM_PRIVACY_STORAGE_BASE"


# create initial db if not present
export PYTHONPATH=$TARGET_DIR/lib:$TARGET_DIR/code
workdir=$(python3 -c "from jobrunner import config; print(config.WORKDIR)")
test -f "$workdir/db.sqlite" || python3 -m jobrunner.cli.migrate

# ensure file ownership and permissions
chown -R opensafely:opensafely $TARGET_DIR
chown -R opensafely:opensafely $HOME_DIR

#clean up old bashrc
rm -rf $HOME_DIR/jobrunner/bashrc

# set up some nice helpers for jobrunner when we su into the shared user
opensafely_bashrc=$HOME_DIR/.bashrc-opensafely
user_bashrc=$HOME_DIR/.bashrc
cp scripts/user.bashrc $opensafely_bashrc
chmod 644 $opensafely_bashrc
test -f $user_bashrc || touch $user_bashrc
grep -q ".bashrc-opensafely" $user_bashrc || echo "test -f $opensafely_bashrc && . $opensafely_bashrc" >> $user_bashrc

# set up systemd service
# Note: do this *after* permissions have been set on the $TARGET_DIR properly
cp $SRC_DIR/jobrunner.service /etc/systemd/system/
cp $SRC_DIR/jobrunner.sudo /etc/sudoers.d/jobrunner

# backend specific unit overrides
test -d "$BACKEND_SRC_DIR/jobrunner.service.d" && cp -Lr "$BACKEND_SRC_DIR/jobrunner.service.d" /etc/systemd/system/

# Dump all the logs if this fails to start
systemctl enable --now jobrunner || (journalctl -xe && exit 1)
