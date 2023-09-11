#!/bin/bash
set -euo pipefail
export VIRTUAL_ENV=~opensafely/osrelease/venv
export OSRELEASE_CONFIG=~/jobrunner/osrelease/config.py
exec $VIRTUAL_ENV/bin/osrelease "$@"
