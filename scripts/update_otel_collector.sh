#!/usr/bin/env bash
set -euo pipefail

script_dir="$(unset CDPATH && cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="$script_dir/../bin"
url_record="$bin_dir/otelcol-contrib-release-url.txt"
output="$bin_dir/otelcol-contrib.zstd"

archive_url="$(
    curl --fail --silent --show-error --location \
        https://api.github.com/repos/open-telemetry/opentelemetry-collector-releases/releases/latest |
        python3 -c '
import json
import re
import sys

release = json.load(sys.stdin)
assets = [
    asset["browser_download_url"]
    for asset in release["assets"]
    if re.fullmatch(r"otelcol-contrib_[^/]+_linux_amd64\.tar\.gz", asset["name"])
]
if len(assets) != 1:
    sys.exit(f"Expected one otelcol-contrib Linux amd64 archive, found {len(assets)}")
print(assets[0])
'
)"

echo "Latest OpenTelemetry Collector release: $archive_url"
if [[ -f "$output" ]] && grep -Fxqs "$archive_url" "$url_record"; then
    echo "Already up to date."
    exit 0
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

curl --fail --silent --show-error --location \
    --output "$tmp_dir/otelcol-contrib.tar.gz" "$archive_url"
tar -xzf "$tmp_dir/otelcol-contrib.tar.gz" -C "$tmp_dir" otelcol-contrib
# We need to compress the vendored binary because the original exceeds Github's limits
zstd -19 --quiet --force "$tmp_dir/otelcol-contrib" -o "$tmp_dir/otelcol-contrib.zstd"

mv -f "$tmp_dir/otelcol-contrib.zstd" "$output"
echo "$archive_url" > "$url_record"
echo "Updated $output"
