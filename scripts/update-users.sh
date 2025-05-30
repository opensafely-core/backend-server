#!/bin/bash
set -euo pipefail

# files containing lists of gh user names for the different roles
# note: probably will be API calls to job-server in future
developers="${developers:-developers}"

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
        # delete and expire their password, forcing reset on first ssh login
        passwd -de "$user"
        # ensure home not world readable
        chmod -R o-rwx "/home/$user"
    fi

    for group in $groups; do
        usermod -a -G "$group" "$user"
    done
    echo "$user groups: $(groups "$user")"

    ./scripts/update-user-ssh-keys.sh "$user"
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

# developers group. They get docker and sudo access.
# Required for all backends
if test -f "$developers"; then
    add_group "$developers" developers researchers reviewers docker sudo
else
    echo "Missing developers file!"
    exit 1
fi
