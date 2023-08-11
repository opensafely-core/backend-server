#!/bin/bash
set -euo pipefail

ref=${1:-HEAD}
TARGET_DIR=/home/jobrunner

cd $TARGET_DIR/code
git fetch --all
git checkout "origin/$ref" --force
sudo systemctl restart jobrunner
