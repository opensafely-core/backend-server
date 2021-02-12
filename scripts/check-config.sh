#!/bin/bash
set -euo pipefail
BACKEND=$1

check_file_pair() {
    local source_path=$1
    local current_path=$2
    local expected
    expected=$(grep -ho '^[A-Z_]\+' "$source_path" | uniq | sort)

    for var in $expected; do
        if ! grep -q "$var=" "$current_path"; then
            echo "$var not found in $current_path"
        fi
    done
}

check_file_pair jobrunner/defaults.env /srv/jobrunner/environ/01_defaults.env
check_file_pair jobrunner/secrets-template.env /srv/jobrunner/environ/02_secrets.env
check_file_pair "$BACKEND/backend.env" /srv/jobrunner/environ/03_backend.env
