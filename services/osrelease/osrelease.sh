#!/bin/bash
set -euo pipefail
export VIRTUAL_ENV=~jobrunner/osrelease/venv
export OSRELEASE_CONFIG=~/jobrunner/osrelease/config.py
exec $VIRTUAL_ENV/bin/osrelease "$@"
