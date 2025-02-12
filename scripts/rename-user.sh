#!/bin/bash
set -euxo pipefail

systemctl stop jobrunner
systemctl stop airlock
systemctl stop collector
systemctl disable jobrunner
systemctl disable airlock
systemctl disable collector

usermod --login opensafely --home /home/opensafely --move-home jobrunner
groupmod --new-name opensafely jobrunner

echo "Re-bootstrap: ./scripts/bootstrap.sh \$NAME"
