#!/bin/bash
set -euo pipefail

# this needs to be called DATABASE_URL in cohortextractor, but we do not want to expose it in telemetry
export DATABASE_URL=$DEFAULT_DATABASE_URL

export OTEL_EXPORTER_OTLP_HEADERS="$(echo $OTEL_EXPORTER_OTLP_HEADERS | sed 's#%20# #g')"

rc=0
otel-cli exec --verbose --fail --name "vmp-mapping-timer" -- docker run --rm --env TEMP_DATABASE_NAME --env DATABASE_URL ghcr.io/opensafely-core/cohortextractor:latest update_vmp_mapping || rc=$?

exit $rc
