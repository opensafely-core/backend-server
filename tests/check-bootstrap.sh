#!/bin/bash
set -euxo pipefail

BACKEND=$1

grep "$BACKEND" /srv/backend-server/.env
grep "$BACKEND" /etc/profile.d/backend.sh
