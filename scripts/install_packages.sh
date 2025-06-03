#!/bin/bash
# Install/update all the base packages.
set -euo pipefail

# running this set -u sometimes causes issues with packaging scripts, it seems
set +u
sed 's/^#.*//' purge-packages.txt | xargs apt-get purge -y
apt-get update
sed 's/^#.*//' core-packages.txt | xargs apt-get install --no-install-recommends -y
sed 's/^#.*//' packages.txt | xargs apt-get install --no-install-recommends -y
apt-get autoremove -y
set -u

if apt list --upgradable 2>/dev/null | grep -q "upgradable from"; then
  echo "=============================== APT UPDATES AVAILABLE ==============================="
  echo
  echo "Newer versions of apt packages are available; you should run:"
  echo
  echo "    just apt-upgrade"
  echo
  echo "====================================================================================="
fi
