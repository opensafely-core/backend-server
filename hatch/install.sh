#!/bin/bash
set -euo pipefail

DIR=~jobrunner/hatch
cp -a ./hatch $DIR
chown -R jobrunner:jobrunner "$DIR"
chmod -R go-rwx "$DIR"

systemctl enable "$DIR/hatch.service"
systemctl enable "$DIR/hatch.timer"
systemctl start hatch.timer
systemctl start hatch.service || { journalctl -u hatch.service; exit 1; }
