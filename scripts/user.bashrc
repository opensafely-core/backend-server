#!/bin/bash

# shellcheck source=/dev/null
test -f ~/config/load-env && . ~/config/load-env

echo -e "
You have logged into the shared opensafely account for managing OpenSAFELY
services on the \033[1m$BACKEND backend\033[0m.

All configuration is in ~/config/*.env, and is sourced into your shell on
login.

Medium privacy files are at \033[1m$MEDIUM_PRIVACY_STORAGE_BASE\033[0m
High privacy files are at \033[1m$HIGH_PRIVACY_STORAGE_BASE\033[0m

jobrunner: ~/jobrunner
airlock: ~/airlock
collector: ~/collector

Please consult ~/playbook.md for operational documentation, or run: just
"

just
