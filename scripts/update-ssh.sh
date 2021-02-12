#!/bin/bash
set -euo pipefail

user=$1

# generate clean authorized_keys file from current sources list. This
# will drop keys that have been removed from this repo or from github
tmp=$(mktemp)

# start with explicit keys from this repo
if test -f "keys/$user"; then
    cat "keys/$user" > "$tmp"
fi

# import current gh keys on top
test "$RATELIMITED" == "true" || ssh-import-id "gh:$user" --output "$tmp"

# replace current authorized_keys
mkdir -p "/home/$user/.ssh"
mv "$tmp" "/home/$user/.ssh/authorized_keys"
