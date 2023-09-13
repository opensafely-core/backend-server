#!/bin/bash
set -euxo pipefail

systemctl stop jobrunner
systemctl stop collector
systemctl disable jobrunner
systemctl disable collector
systemctl disable release-hatch.service
systemctl disable release-hatch.timer

docker-compose -f ~opensafely/release-hatch/docker-compose.yaml stop release-hatch

usermod --login opensafely --home /home/opensafely --move-home jobrunner
groupmod --new-name opensafely jobrunner

echo "Re-bootstrap: ./scripts/bootstrap.sh \$NAME"
