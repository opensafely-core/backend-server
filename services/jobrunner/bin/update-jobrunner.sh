#!/bin/bash
set -euo pipefail

ref=${1:-HEAD}
TARGET_DIR=/home/opensafely

cd $TARGET_DIR/code
git fetch --all
git checkout "origin/$ref" --force
sudo systemctl restart jobrunner
