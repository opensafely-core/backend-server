#!/bin/bash
# Install emis-specific packages.
set -euo pipefail

# install packages required for nfs mount
apt-get install --no-install-recommends -y nfs-common
