#!/bin/bash
set -euo pipefail
BACKEND_DIR=$1

DIR=~jobrunner/job-runner
cp -a ./job-runner "$DIR"
chown -R jobrunner:jobrunner "$DIR"
chmod -R go-rwx "$DIR"

./scripts/jobrunner-config.sh "$BACKEND_DIR"

# TODO: backend specific unit overrides

systemctl enable "$DIR/job-runner.service"
systemctl enable "$DIR/job-runner.timer"
systemctl start job-runner.timer
systemctl start job-runner.service || { journalctl -u job-runner.service; exit 1; }
