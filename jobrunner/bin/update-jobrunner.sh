#!/bin/bash
set -euo pipefail

ref=${1:-HEAD}

cd /srv/jobrunner/code
git fetch
git checkout "$ref"
sudo systemctl restart jobrunner
