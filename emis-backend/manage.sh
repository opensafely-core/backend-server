#!/bin/bash
set -euo pipefail

# we currently can not install new packages in EMIS, as we don't have access to
# ubuntu archives. The packages core-packages.txt are already installed.
# 
# To simulate this in these tests, we uninstall packages.txt from the test
# docker image, to make sure everything still works
set +u
sed 's/^#.*//' packages.txt | xargs apt-get remove -y
apt-get autoremove -y
set -u

# ok, lets go!

export INSTALL_PACKAGES=false  # don't install stuff as per above
./scripts/install.sh

./scripts/update-users.sh developers emis-backend/researchers emis-backend/reviewers
./scripts/jobrunner.sh emis-backend
./hatch/install.sh
./osrelease/setup.sh

for f in /srv/jobrunner/environ/*.env; do
    # shellcheck disable=SC1090
    . "$f"
done


if test -z "${PRESTO_TLS_KEY_PATH:-}"; then
    echo "WARNING: PRESTO_TLS_KEY_PATH env var not defined"
else
    test -e "${PRESTO_TLS_KEY_PATH:-}" ||  echo "WARNING: PRESTO_TLS_KEY_PATH=$PRESTO_TLS_KEY_PATH does not exist"
fi
if test -z "${PRESTO_TLS_CERT_PATH:-}"; then
    echo "WARNING: PRESTO_TLS_CERT_PATH env var not defined"
else
    test -e "${PRESTO_TLS_CERT_PATH:-}" ||  echo "WARNING: PRESTO_TLS_CERT_PATH=$PRESTO_TLS_CERT_PATH does not exist"
fi
