#!/bin/bash
set -euo pipefail
verbose=${1:-}
tmp=$(mktemp)
for job in $(docker ps -f label=org.opensafely.action=cohortextractor | grep -oE "os-job-.*")
do
  docker logs --tail 10000 "$job" |& tac | grep -Em 1 '^2022-' -B10000 | tac > "$tmp" || true
  ts=$(grep -oE "202.-..-.. ..:..:..:" "$tmp")
  now=$(date +%s)
  time=$(date -d "$ts" +%s)
  delta=$((now - time))
  days=$((delta / 86400))
  hours=$(( (delta % 86400) / 3600 ))
  minutes=$(( (delta % 3600) / 60 ))
  seconds=$((delta % 60))
  echo "$ts: $job: ${days}days, $hours:$minutes:$seconds"
  test -n "$verbose" && { cat "$tmp"; echo; }
done
