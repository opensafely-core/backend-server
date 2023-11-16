#!/bin/bash
set -euo pipefail

ref=${1:-origin/main}
TARGET_DIR=/home/opensafely/jobrunner/code

cd $TARGET_DIR
git fetch --all
if ! git diff-files --quiet; then
    echo "Dirty checkout in $TARGET_DIR. Please fix by either:"
    echo " a) stashing/removing local changes and re-running this command, or"
    echo " b) manually checking out the ref you want and running 'just jobserver/restart'"
    exit 1
fi

echo "Pending commits:"
git log --ancestry-path HEAD..$ref

if test -t 1; then
    echo "Confirm you wish to deploy the above changes"
    read -p "Are you sure (y/n)? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        exit 1
    fi
fi
git reset "$ref" --hard
sudo systemctl restart jobrunner
