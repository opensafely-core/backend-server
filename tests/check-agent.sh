#!/bin/bash
set -euo pipefail

source /home/opensafely/config/load-env


tout() {
	local duration=$1
	shift

	code=0
    timeout --foreground "$duration" "$@" || code=$?

	if test "$code" == "124"; then
		echo "Timeout waiting for: $*"
	fi
	return $code
}


script=$(mktemp)
cat << EOF > "$script"
until journalctl -t agent -n 100 | grep -qF 'agent.main loop started'
do
    sleep 2
done
EOF

tout 60s bash "$script" || { journalctl -t agent; exit 1; }
