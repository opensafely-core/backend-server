#!/bin/bash
set -euxo pipefail

# set DNS for RELEASE_HOST to 127.0.0.1
# shellcheck source=/dev/null
source <(cat /home/jobrunner/config/*.env)
HOSTNAME="$(echo "$RELEASE_HOST" | cut -d'/' -f3 | cut -d':' -f1)"
grep -q "$HOSTNAME" /etc/hosts || echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

# run release-hatch tests
docker-compose -f ~jobrunner/release-hatch/docker-compose.yaml run --rm release-hatch-test

# check CORS preflight
cors_check=0
curl -s --fail "$RELEASE_HOST" -X OPTIONS \
  -H 'Access-Control-Request-Method: GET' \
  -H 'Access-Control-Request-Headers: authorization' \
  -H 'Origin: https://jobs.opensafely.org' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-site' \
  -H 'Sec-Fetch-Dest: empty' || cors_check=$?

if test $cors_check != 0; then
   echo "CORS preflight check failed with exit code $cors_check"
   exit $cors_check
fi
