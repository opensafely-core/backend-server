#!/bin/bash
set -euo pipefail

./scripts/bootstrap.sh tpp

./tests/check-bootstrap.sh tpp

just manage

# Fake a minimal controller HTTP endpoint
controller_port=8000
controller_tmpdir="$(mktemp -d)"
mkdir -p "$controller_tmpdir/tpp/tasks"
echo '{"tasks": []}' > "$controller_tmpdir/tpp/tasks/index.html"
python3 -m http.server -d "$controller_tmpdir" "$controller_port" &
controller_pid=$!
trap "kill $controller_pid 2>/dev/null" EXIT INT TERM

# Override the config to point the agent at our fake controller (IP is Docker gateway)
echo -e "\nCONTROLLER_TASK_API_ENDPOINT=http://172.17.0.1:$controller_port/" >> /home/opensafely/config/04_local.env

# jobrunner.service runs `just deploy` which will not start jobrunner if it not
# already running, so manually start it here
just -f ~opensafely/jobrunner/justfile start

# run again to check for idempotency
just manage

# test for ssh keys
grep -q SimonDavy@OPENCORONA ~bloodearnest/.ssh/authorized_keys

sleep 3

# test jobrunner service up
docker compose -f ~opensafely/jobrunner/docker-compose.yaml exec agent true || { docker compose -f ~opensafely/jobrunner/docker-compose.yaml logs; exit 1; }

# test collector service up
./tests/check-collector.sh

# run airlock tests
./tests/check-airlock.sh
