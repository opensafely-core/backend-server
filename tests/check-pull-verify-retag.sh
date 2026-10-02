#!/bin/bash
set -euo pipefail

# This test uses tiny signed and unsigned images built from these commits:
#
# https://github.com/opensafely-core/job-runner/commit/cba415f82ab236003718b2ef196e49a4cfa1720c
# ghcr.io/opensafely-core/job-runner:test-fixture-signed
#
# https://github.com/opensafely-core/job-runner/commit/2ca2077cf0ea00a809af6752d2b3ed413e8b5e7a
# ghcr.io/opensafely-core/job-runner:test-fixture-unsigned

# Start from a clean slate
docker image rm local/test-image:verified 2>/dev/null || true 

image='docker-proxy.opensafely.org/opensafely-core/job-runner'
common_args=(
   --target-ref local/test-image:verified
   --github-repo opensafely-core/job-runner
   --branch test-fixtures
   --trusted-root /etc/opensafely/sigstore_trusted_root.json
)

pull_verify_retag.py "$image:test-fixture-signed" "${common_args[@]}"

# Confirm that the local tag points to the expected image
docker run --rm local/test-image:verified | grep -q 'I am a signed image'

# Confirm that the unsigned fixture behaves as expected
docker run --rm "$image:test-fixture-unsigned" | grep -q 'I am an unsigned image'

# We expect this to fail verification
set +e
pull_verify_retag.py "$image:test-fixture-unsigned" "${common_args[@]}" >/dev/null
set -e

# Confirm the local tag has not been updated
docker run --rm local/test-image:verified | grep -q 'I am a signed image'
