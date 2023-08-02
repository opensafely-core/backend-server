#!/bin/bash
set -euo pipefail

export INSTALL_PACKAGES=false  # don't install stuff as per above
./scripts/install.sh

./scripts/update-users.sh developers emis-backend/researchers emis-backend/reviewers
./services/jobrunner/install.sh emis-backend
./release-hatch/install.sh
./services/osrelease/install.sh

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
