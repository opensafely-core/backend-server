#!/bin/bash
set -eu -o pipefail

# shellcheck source=/dev/null
. scripts/load-env

DIR=/home/opensafely/collector
mkdir -p "$DIR"

BIN=$DIR/collector

cp services/collector/* "$DIR"
rm -f "$BIN"
cp bin/otelcol_hny_linux_amd64-* "$BIN"
chmod +x "$BIN"

chown -R opensafely:opensafely "$DIR"
chmod -R go-rwx "$DIR"

# Add env vars required for docker-compose.yaml
{
  echo "BASE_DOMAIN=\"$BASE_DOMAIN\""
} >> $DIR/.env

systemctl enable "$DIR/collector.service"
systemctl start collector.service || { journalctl -u collector.service; exit 1; }
