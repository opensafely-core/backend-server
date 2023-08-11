#!/bin/bash
set -euo pipefail
verbose=${1:-}
tmp=$(mktemp)
for job in $(docker ps -f label=org.opensafely.action=cohortextractor | grep -oE "os-job-.*")
do
  docker logs --tail 10000 "$job" |& tac | grep -Em 1 '^2022-' -B10000 | tac > "$tmp" || true
  ts=$(grep -oE "202.-..-.. ..:..:..:" "$tmp")
  delta=$(python3 -c "from datetime import datetime; d = datetime.now() - datetime.fromisoformat(\"$ts\"); print(d)")
  echo "$ts: $job: $delta"
  test -n "$verbose" && { cat "$tmp"; echo; }
done
