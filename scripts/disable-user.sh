#!/bin/bash
set -euo pipefail

user=${1}

log=$(mktemp)

find_user() {
    local file=$1
    if test -f "$file"; then
        if grep -q "$user" "$file"; then
            echo "$user still in $file - you must remove them from active user list to disable"
            exit 1
        fi
    fi
}

find_user developers
find_user "backends/$BACKEND/reviewers"
find_user "backends/$BACKEND/researchers"

# remove ssh auth
rm -f "/home/$user/.ssh/authorized_keys"

remove_group() {
    local rc=0
    gpasswd --delete "$user" "$1" 2> "$log"  || rc=$?
    if test "$rc" == 0 -o "$rc" == "3"; then 
       return
    fi
    cat "$log"
    exit $rc
}

remove_group developers
remove_group reviewers
remove_group researchers

# disable login for this user
passwd --delete --lock "$user"

echo "Disabling login for $user"
usermod --lock --expiredate 1 --shell /bin/nologin "$user"

