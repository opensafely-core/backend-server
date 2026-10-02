#!/bin/bash

# We need to install the SigStore Cosign tool to do signature verification for our
# Docker images. This is available in the standard Ubuntu archives for Resolute 26.04
# onwards, but not for earlier versions. Ordinarily mixing packages from different
# releases would be fragile and error prone, but Cosign is deliberately built as a
# standalone Go binary and its only [dependency][1] is `libc6>=2.34`, which 22.04
# already satisfies.
#
# There's a little bit of chicanery to get the Apt configuration right, but the upside
# is that we can install and update Cosign through the standard mechanisms, including
# getting regular unattended upgrades for it. So it's definitely worth it.
#
# And when we eventually upgrade the base OS to Resolute this will all go away.
#
# [1]: https://packages.ubuntu.com/resolute/cosign


set -euo pipefail
script_dir="$( unset CDPATH && cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# If we're already running on Resolute 26.04 or later then there's nothing to do here
if dpkg --compare-versions "$(. /etc/os-release; echo "$VERSION_ID")" ge "26.04"; then
    exit 0
fi

src_dir="$script_dir/../etc/resolute-cosign-apt"
dst_dir="/etc/apt"

echo 'Configuring Resolute 26.04 sources for Cosign package'

# Give all Resolute packages apart from Cosign a negative pin priority which prevents
# them being installed. Give Cosign the standard priority.
cp "$src_dir/preferences.d_resolute-cosign.pref" \
   "$dst_dir/preferences.d/resolute-cosign.pref"

# Add Resolute archives as available sources
cp "$src_dir/sources.list.d_resolute-cosign.sources" \
   "$dst_dir/sources.list.d/resolute-cosign.sources"

# Allow unattended upgrades for Resolute packages i.e. just for Cosign
cp "$src_dir/apt.conf.d_52unattended-upgrades-resolute-cosign" \
   "$dst_dir/apt.conf.d/52unattended-upgrades-resolute-cosign"
