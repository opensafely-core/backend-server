#!/bin/bash
set -euo pipefail

backend=$1

err() {
    journalctl --no-pager -u collector
    exit 1
}

systemctl status --no-pager collector >/dev/null || err

# check that the rap.backend attribute has been configured
journalctl --no-pager -u collector | grep "\"rap.backend\":\"$backend\"" > /dev/null || err

# check that there is trace data from airlock/agent
journalctl --no-pager -u collector | grep "TracesExporter" > /dev/null || err

