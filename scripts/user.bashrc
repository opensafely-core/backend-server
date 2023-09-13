#!/bin/bash
# load config into this shell so we can just run stuff
set -a
# shellcheck disable=SC1090
for f in /home/opensafely/config/*.env; do
    . "$f"
done
set +a

# let opensafely user use the opensafely commands and scripts easily
export PYTHONPATH=/home/opensafely/jobrunner/code:/home/opensafely/jobrunner/lib
export PATH=$PATH:/home/opensafely/jobrunner/bin:/home/opensafely/jobrunner/code/scripts

echo -e "
You have logged into the shared opensafely account for managing OpenSAFELY
services on the \033[1m$BACKEND backend\033[0m.

All configuration is in ~/config/*.env, and is sourced into your shell on
login.

Medium privacy files are at \033[1m$MEDIUM_PRIVACY_STORAGE_BASE\033[0m
High privacy files are at \033[1m$HIGH_PRIVACY_STORAGE_BASE\033[0m

jobrunner: ~/jobrunner
release-hatch: ~/release-hatch
collector: ~/collector

Please consult ~/playbook.md for operational documentation, or run: just
"

just
