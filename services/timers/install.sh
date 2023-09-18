#!/bin/bash
set -euo pipefail

DIR=/home/opensafely/timers

# shellcheck source=/dev/null
. /home/opensafely/config/load-env
mkdir -p "$DIR"
cp -r services/timers/* "$DIR"
chown -R opensafely:opensafely "$DIR"

timers=$(env -C $DIR find -maxdepth 1 -mindepth 1 -type d | sed 's#\./##g') 

for timer in $timers; do
    timer_dir="$DIR/$timer"
    if test -f "$timer_dir/backends"; then
       grep -q "$BACKEND" "$timer_dir/backends" || continue
    fi
    systemctl enable "$timer_dir/$timer.timer"
    systemctl enable "$timer_dir/$timer.service"
done

