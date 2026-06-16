#!/bin/bash
# Install/update all the base packages.
set -euo pipefail

# Rewrite apt sources to use our proxy. This operation is idempotent so we can just run
# it every time. We handle both newer and older style layouts so this doesn't become
# another thing to change when we update base Ubuntu versions
for target in /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources; do
  [[ -e "$target" ]] || continue

  sed --in-place --regexp-extended \
    's#http://(archive|security)\.ubuntu\.com/#https://\1-ubuntu.opensafely.org/#g' \
    "$target"
done

# running this set -u sometimes causes issues with packaging scripts, it seems
set +u
apt-get update
sed 's/^#.*//' purge-packages.txt | xargs apt-get purge -y
sed 's/^#.*//' core-packages.txt | xargs apt-get install --no-install-recommends --no-upgrade -y
sed 's/^#.*//' packages.txt | xargs apt-get install --no-install-recommends --no-upgrade -y
apt-get autoremove -y
set -u

# Because upgrading Docker involves killing all running containers we need to coordinate
# when it happens and don't want it happening automatically. There is special code in
# `just apt-upgrade` to handle this package.
apt-mark hold docker.io

if apt list --upgradable 2>/dev/null | grep -q "upgradable from"; then
  echo "=============================== APT UPDATES AVAILABLE ==============================="
  echo
  echo "Newer versions of apt packages are available; you should run:"
  echo
  echo "    just apt-upgrade"
  echo
  echo "====================================================================================="
fi
