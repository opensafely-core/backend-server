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
        useradd "$user"
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

# developers is mandatory
add_group "$developers" developers researchers reviewers

# other groups depend on backend
if test -f "$researchers"; then
    add_group "$researchers" researchers reviewers
fi

if test -f "$reviewers"; then
    add_group "$reviewers" reviewers
fi
