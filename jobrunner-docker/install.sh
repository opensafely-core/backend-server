#!/bin/bash
set -euo pipefail

DIR=~jobrunner/job-runner

./scripts/jobrunner-config.sh

# TODO: backend specific unit overrides


cp -a ./job-runner "$DIR"
chown -R jobrunner:jobrunner "$DIR"
chmod -R go-rwx "$DIR"

systemctl enable "$DIR/job-runner.service"
systemctl enable "$DIR/job-runner.timer"
systemctl start job-runner.timer
systemctl start job-runner.service || { journalctl -u job-runner.service; exit 1; }
