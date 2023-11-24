#!/bin/bash
set -euo pipefail

run() {
    echo "$@"
    # shellcheck disable=SC2068
    $@
}

ref=${1:-origin/main}
TARGET_DIR=/home/opensafely/jobrunner/code

cd $TARGET_DIR
run git fetch --all
if ! git diff-files --quiet; then
    echo "Dirty checkout in $TARGET_DIR. Please fix by either:"
    echo " a) stashing/removing local changes and re-running this command, or"
    echo " b) manually checking out the ref you want and running 'just jobserver/restart'"
    exit 1
fi

echo "Pending commits:"
git --no-pager log --ancestry-path "HEAD..$ref"

if test -t 1; then
    echo "Confirm you wish to deploy the above changes"
    read -p "Are you sure (y/n)? " -n 1 -r
    echo
    if ! [[ $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo
echo "Updating python dependencies..."
run git -C jobrunner/lib pull

echo
echo "Checking out $ref..."
git reset "$ref" --hard

echo
echo "Running migrations..."
run python3 -m jobrunner.cli.migrate

echo
echo "Restarting jobrunner..."
run sudo systemctl restart jobrunner

echo 
echo "Checking status..."
run systemctl status jobrunner --no-pager
