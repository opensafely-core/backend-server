#!/bin/bash
set -euo pipefail

./scripts/install.sh
./scripts/update-users.sh developers emis-backend/researchers emis-backend/reviewers
./scripts/jobrunner.sh emis-backend
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
