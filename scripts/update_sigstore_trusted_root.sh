#!/bin/bash

# This fetches a copy of the SigStore trust root file which Cosign needs to be able to
# verify signatures without additional network access.
# 
# We fetch directly from the [Github repo][1] and are intentionally not using the [TUF
# framework][2] because we believe the additional [complexity][3] that involves is of limited
# benefit in our context.
#
# [1]: https://github.com/sigstore/root-signing/blob/main/targets/trusted_root.json
# [2]: https://theupdateframework.io/
# [3]: https://blog.sigstore.dev/the-update-framework-and-you-2f5cbaa964d5/

set -euo pipefail
script_dir="$( unset CDPATH && cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

curl --location \
  https://raw.githubusercontent.com/sigstore/root-signing/refs/heads/main/targets/trusted_root.json \
  --output "$script_dir/../etc/opensafely/sigstore_trusted_root.json"
