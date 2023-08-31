#!/bin/bash
set -euo pipefail

# Set up the job-runner service
SRC_DIR=services/jobrunner
BACKEND_SRC_DIR=backends/$1
HOME_DIR=/home/jobrunner
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
cp $SRC_DIR/sbin/* /usr/local/sbin

# setup output directories
for output_dir in "$HIGH_PRIVACY_STORAGE_BASE" "$MEDIUM_PRIVACY_STORAGE_BASE"; do
    mkdir -p "$output_dir/workspaces"
    # only group read access, no world access
    find "$output_dir" -type f -exec chmod 640 {} +
done
chown -R jobrunner:jobrunner "$HIGH_PRIVACY_STORAGE_BASE"
chown -R "jobrunner:$REVIEWERS_GROUP" "$MEDIUM_PRIVACY_STORAGE_BASE"


# create initial db if not present
test -f $TARGET_DIR/code/workdir/db.sqlite || PYTHONPATH=$TARGET_DIR/lib:$TARGET_DIR/code python3 -m jobrunner.cli.migrate

# ensure file ownership and permissions
chown -R jobrunner:jobrunner $TARGET_DIR
chown -R jobrunner:jobrunner $HOME_DIR

# set up some nice helpers for jobrunner when we su into the shared user
jobrunner_bashrc=$TARGET_DIR/bashrc
user_bashrc=$HOME_DIR/.bashrc
cp $SRC_DIR/bashrc $jobrunner_bashrc
chmod 644 $jobrunner_bashrc
test -f $user_bashrc || touch $user_bashrc
grep -q "jobrunner/bashrc" $user_bashrc || echo "test -f $jobrunner_bashrc && . $jobrunner_bashrc" >> $user_bashrc

# set up systemd service
# Note: do this *after* permissions have been set on the $TARGET_DIR properly
cp $SRC_DIR/jobrunner.service /etc/systemd/system/
cp $SRC_DIR/jobrunner.sudo /etc/sudoers.d/jobrunner

# backend specific unit overrides
test -d "$BACKEND_SRC_DIR/jobrunner.service.d" && cp -Lr "$BACKEND_SRC_DIR/jobrunner.service.d" /etc/systemd/system/

# Dump all the logs if this fails to start
systemctl enable --now jobrunner || (journalctl -xe && exit 1)
