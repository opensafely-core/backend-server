#!/bin/bash
set -euo pipefail

# files containing lists of gh user names for the different roles
# note: probably will be API calls to job-server in future
developers=$1
researchers=${2:-}
reviewers=${3:-}

# add a user, add to groups, and
add_user() {
    local user=$1
    shift
    local groups=$*
    if id -u "$user" > /dev/null 2>&1; then
        echo "User $user already exists"
    else
        echo "Adding user $user"
        useradd "$user" --create-home --shell /bin/bash
    fi

    for group in $groups; do
        usermod -a -G "$group" "$user"
    done
    echo "$user groups: $(groups "$user")"

    ./scripts/update-ssh.sh "$user"
}

# add a list of users from a file, to specific groups
add_group() {
    local file=$1
    shift
    local groups="$*"
    while read -r user; do
        if test "${user::1}" = "#"; then  # skip comments
            continue
        elif test -z "$user"; then  # skip blank lines
            continue
        else
            add_user "$user" "$groups"
        fi
    done < "$file"
}

# developers is mandatory. They get docker and sudo access
add_group "$developers" developers researchers reviewers docker sudo

# Note: the following groups are optional, depends on how the users will
# authenticate with the specific backend

# optional researchers (level 3) group. They got docker to be able manually run stuff if needed.
if test -f "$researchers"; then
    add_group "$researchers" researchers reviewers docker
fi

# optional reviewers (level 4) group. Minimial permissions. Long term goal is
# no local accounts needed for this group, but early EMIS backend set up
# requires them.
if test -f "$reviewers"; then
    add_group "$reviewers" reviewers
fi
