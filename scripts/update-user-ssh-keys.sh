#!/bin/bash
set -euo pipefail

user=$1
TEST=${TEST:-}

# generate clean authorized_keys file from current sources list. This
# will drop keys that have been removed from this repo or from github
tmp=$(mktemp)

# start with explicit keys from this repo
if test -f "keys/$user"; then
    cat "keys/$user" > "$tmp"
fi

# workaround for gh ratelimits when runing tests locally
cache=.ssh-key-cache/$user
# if we have a cached file, and TEST is set, then use cache
if test -f "$cache" -a -n "${TEST}"; then
    cat "$cache" >> "$tmp"
else
    # add current gh keys into $tmp
    # note: a quirk of the github ssh api here is that a non-existent user
    # returns an empty 200 response. Which is handy here for using with test
    # users
    curl --silent --fail "https://github-proxy.opensafely.org/$user.keys" >> "$tmp"
fi

# ensure .ssh directory exists
ssh_directory="/home/$user/.ssh"
mkdir -p "$ssh_directory"
chown -R "$user:$user" "$ssh_directory"
chmod -R 0700 "$ssh_directory"

# replace authorized_keys file
authorized_keys_file="$ssh_directory/authorized_keys"
mv "$tmp" "$authorized_keys_file"
chown "$user:$user" "$authorized_keys_file"
chmod 0600 "$authorized_keys_file"
