#!/bin/bash
# Install emis-specific packages.
set -euo pipefail

# shellcheck source=/dev/null
. /srv/backend-server/scripts/load-env

wget https://github.com/benbjohnson/litestream/releases/download/v0.5.8/litestream-0.5.8-linux-x86_64.deb
dpkg -i litestream-0.5.8-linux-x86_64.deb
rm litestream-0.5.8-linux-x86_64.deb

cp /srv/backend-server/services/litestream/litestream.yml /etc/litestream.yml

AIRLOCK_DB_FILE="${AIRLOCK_HOST_BASEDIR}/workdir/db.sqlite3"
AIRLOCK_DB_REPLICA_PATH="${AIRLOCK_DB_REPLICA_PATH}"

sed -i "s|^ - path:.*| - path: ${AIRLOCK_DB_FILE}|" /etc/litestream.yml
sed -i "s|^     path:.*|     path: ${AIRLOCK_DB_REPLICA_PATH}|" /etc/litestream.yml

systemctl enable litestream
systemctl start litestream  || { journalctl -u litestream; exit 1; }
