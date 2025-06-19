#!/bin/bash
set -euo pipefail

err() {
    journalctl --no-pager -u collector
    exit 1
}

systemctl status --no-pager collector >/dev/null || err
journalctl --no-pager -u collector | grep "rap.backend" > /dev/null || err


