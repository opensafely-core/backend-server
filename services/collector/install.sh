#!/bin/bash
set -eu -o pipefail

DIR=/home/opensafely/collector
mkdir -p "$DIR"

BIN=$DIR/collector

cp services/collector/* "$DIR"
rm -f "$BIN"
cp bin/otelcol_hny_linux_amd64-* "$BIN"
chmod +x "$BIN"

chown -R opensafely:opensafely "$DIR"
chmod -R go-rwx "$DIR"

systemctl enable "$DIR/collector.service"
systemctl start collector.service || { journalctl -u collector.service; exit 1; }
