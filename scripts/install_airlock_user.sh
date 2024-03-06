#!/bin/bash
set -euo pipefail

HOME_DIR=/home/airlock

# set default file creation permission for this script be 640 for files and 750
# for directories
umask 027


# ensure shared user is set up properly
if id -u airlock 2>/dev/null; then
    # ensure airlock can access the relevant files
    usermod -a -G reviewers opensafely
    # ensure opensafely group ids
    usermod -u 10006 airlock
    groupmod -g 10006 airlock
else
    useradd airlock --create-home --shell /bin/bash --uid 10006 -G reviewers
fi
