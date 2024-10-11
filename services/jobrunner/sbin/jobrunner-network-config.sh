#!/bin/bash

# Creates a Docker network and configures it to have access to only the
# specified list of IPs. Example usage:
#
#   jobrunner-network-config.sh my-network-name 8.8.8.8 170.30.0.0/16
#
# Requires root in order to call `iptables`.

set -euo pipefail

network_name="$1"
shift 1

insert_iptables_rule() {
  # iptables rule insertion is not idempotent, so we need to check if the rule
  # already exits or we'll end up with duplicates
  if ! iptables --check "$@" &>/dev/null; then
    iptables -I "$@"
  fi
}

# Add a default REJECT rule for requests from this interface
insert_iptables_rule DOCKER-USER -i "$network_name" -j REJECT

# Add ACCEPT rules for each of the supplied arguments
while [[ "$#" != "0" ]]; do
  ip_addr_specs="$1"
  shift 1
  # Given the way that systemd handles arguments we can end up with multiple
  # addresses in a single space-separated argument; so we iterate over them
  # here
  for ip_addr_spec in $ip_addr_specs; do
    insert_iptables_rule DOCKER-USER -i "$network_name" -d "$ip_addr_spec" -j ACCEPT
  done
done

# Check if the Docker network already exists and has the expected interface name
existing_network=$(
  docker network inspect "$network_name" \
  --format '{{ index .Options "com.docker.network.bridge.name" }}' \
    2>/dev/null \
  || true
)

# Create the network if it doesn't exist
if [[ "$existing_network" != "$network_name" ]]; then
  # Note that if the network does exist but for some reason does not use the
  # expected interface name then the below command will blow up, which is
  # better than adding iptables rules which silently have no effect.
  docker network create \
    --driver bridge \
    -o com.docker.network.bridge.name="$network_name" \
    "$network_name" \
      >/dev/null
fi
