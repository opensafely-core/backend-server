#!/bin/bash
set -eu -o pipefail

DIR=/home/opensafely/collector
mkdir -p "$DIR"

BIN=$DIR/collector

cp services/collector/* "$DIR"
rm -f "$BIN"

# Decompress beside the destination, then atomically replace the executable.
if [[ bin/otelcol-contrib.zstd -nt "$BIN" ]]; then
    otelcol_tmp="$(mktemp "$DIR/.otelcol-contrib.XXXXXX")"
    trap 'rm -f "$otelcol_tmp"' EXIT
    zstd --decompress --stdout bin/otelcol-contrib.zstd > "$otelcol_tmp"
    chmod 0755 "$otelcol_tmp"
    mv -f "$otelcol_tmp" "$BIN"
    trap - EXIT
fi

chown -R opensafely:opensafely "$DIR"
chmod -R go-rwx "$DIR"

systemctl enable "$DIR/collector.service"
systemctl start collector.service || { journalctl -u collector.service; exit 1; }
