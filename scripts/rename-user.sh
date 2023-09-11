#!/bin/bash
set -euxo pipefail


systemctl stop jobrunner
systemctl stop collector
docker-compose -f ~opensafely/release-hatch/docker-compose.yaml stop release-hatch

usermod --login opensafely --home /home/opensafely --move-home jobrunner

