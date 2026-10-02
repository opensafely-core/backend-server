#!/bin/bash
# Install emis-specific packages.
set -euo pipefail

# nfs-common - required for nfs mount(for EFS)
# postgresql-client - required for psql (not required for airlock to run, but useful for inspecting the db)
apt-get update && \
  apt-get install --no-install-recommends --no-upgrade -y nfs-common postgresql-client 
