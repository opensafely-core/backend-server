#!/bin/bash
set -euo pipefail

HOME_DIR=/home/opensafely

# set default file creation permission for this script be 640 for files and 750
# for directories
umask 027


# ensure shared user is set up properly
if id -u opensafely 2>/dev/null; then
    # ensure opensafely is in docker group
    usermod -a -G docker opensafely
    # ensure opensafely group ids
    usermod -u 10000 opensafely
    groupmod -g 10000 opensafely
else
    useradd opensafely --create-home --shell /bin/bash --uid 10000 -G docker
    # TODO verify opensafely gid is 10000
fi

chmod -R 0750 $HOME_DIR

# update playbook
# explicitly remove it first, in case it's a symlink to an old location
rm -f $HOME_DIR/playbook.md
cp playbook.md $HOME_DIR/playbook.md
# clean up old playbook if present
rm -f /srv/playbook.md

#clean up old bashrc
rm -rf $HOME_DIR/jobrunner/bashrc

# set up some nice helpers for when we su into the shared user
opensafely_bashrc=$HOME_DIR/.bashrc-opensafely
user_bashrc=$HOME_DIR/.bashrc
cp scripts/user.bashrc $opensafely_bashrc
chmod 644 $opensafely_bashrc
test -f $user_bashrc || touch $user_bashrc
grep -q ".bashrc-opensafely" $user_bashrc || echo "test -f $opensafely_bashrc && . $opensafely_bashrc" >> $user_bashrc

# update user-wide justfiles for management tasks
cp justfile-user $HOME_DIR/justfile
