#!/bin/bash
set -euo pipefail

DIR=~jobrunner/release-hatch
cp -a ./release-hatch "$DIR"
chown -R jobrunner:jobrunner "$DIR"
chmod -R go-rwx "$DIR"

systemctl enable "$DIR/release-hatch.service"
systemctl enable "$DIR/release-hatch.timer"
systemctl start release-hatch.timer
systemctl start release-hatch.service || { journalctl -u release-hatch.service; exit 1; }
