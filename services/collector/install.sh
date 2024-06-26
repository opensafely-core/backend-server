#!/bin/bash
set -eu -o pipefail

DIR=/home/opensafely/collector
mkdir -p "$DIR"

BIN=$DIR/collector

cp services/collector/* "$DIR"

# curl sometimes complains about overwriting files, so download to tmp
curl -s https://github-proxy.opensafely.org/opensafely-core/backend-server/releases/download/v0.1/otelcol_hny_linux_amd64 -o /tmp/collector
mv /tmp/collector "$BIN"
chmod +x "$BIN"

chown -R opensafely:opensafely "$DIR"
chmod -R go-rwx "$DIR"

systemctl enable "$DIR/collector.service"
systemctl start collector.service || { journalctl -u collector.service; exit 1; }
