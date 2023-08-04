#!/bin/bash
# Install/update all the base packages.
set -euo pipefail

# running this set -u sometimes causes issues with packaging scripts, it seems
set +u
sed 's/^#.*//' purge-packages.txt | xargs apt-get purge -y
apt-get update
apt-get upgrade -y
sed 's/^#.*//' core-packages.txt | xargs apt-get install -y
sed 's/^#.*//' packages.txt | xargs apt-get install -y
apt-get autoremove -y
set -u
