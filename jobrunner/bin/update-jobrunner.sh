#!/bin/bash
set -euo pipefail

ref=${1:-HEAD}

cd /srv/jobrunner/code
git fetch --all
git checkout "origin/$ref" --force
sudo systemctl restart jobrunner
