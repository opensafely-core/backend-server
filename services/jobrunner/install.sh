#!/bin/bash
set -euo pipefail

BACKEND=$1

# Set up the job-runner service
SRC_DIR=services/jobrunner
BACKEND_SRC_DIR=backends/$BACKEND
HOME_DIR=/home/opensafely
DIR=$HOME_DIR/jobrunner

# set default file creation permission for this script be 640 for files and 750
# for directories
umask 027

# shellcheck source=/dev/null
. scripts/load-env


# set up jobrunner
mkdir -p $DIR/workdir
cp -a services/jobrunner/* $DIR/
cp $SRC_DIR/bin/* ~opensafely/bin/
# setup some automated config for docker group id
echo "DOCKER_HOST_GROUPID=$(getent group docker | awk -F: '{print $3}')" > $DIR/.env

chown -R opensafely:opensafely $DIR

# TODO: this should probably live somewhere else, as its more than just a jobrunner thing
# setup output directories
for output_dir in "$HIGH_PRIVACY_STORAGE_BASE" "$MEDIUM_PRIVACY_STORAGE_BASE"; do
    mkdir -p "$output_dir/workspaces"
    # only group read access, no world access
    find "$output_dir" -type f -exec chmod 640 {} +
done

chown -R opensafely:opensafely "$HIGH_PRIVACY_STORAGE_BASE" "$MEDIUM_PRIVACY_STORAGE_BASE"

# backend specific unit overrides
test -d "$BACKEND_SRC_DIR/jobrunner.service.d" && cp -Lr "$BACKEND_SRC_DIR/jobrunner.service.d" $DIR/

chown -R opensafely:opensafely "$DIR"

systemctl enable "$DIR/jobrunner.service"
systemctl enable "$DIR/jobrunner.timer"
systemctl start jobrunner.timer
systemctl start jobrunner.service || { journalctl -u jobrunner.service; exit 1; }
