#!/bin/bash
# Run an ephemeral lxd container, to simulate a VM
#
# Run with DEBUG=1 to run a shell inside the container after running your
# script
# 
set -euo pipefail
SCRIPT=$1
LOG=$SCRIPT.log
TEST_IMAGE=backend-server-test
DEBUG=${DEBUG:-}
TRACE=${TRACE:-}
DOCKER_SHELLOPTS=
GITHUB_ACTIONS=${GITHUB_ACTIONS:-"false"}
BACKEND_SERVER_DIR=/srv/backend-server

test -n "$TRACE" && DOCKER_SHELLOPTS=xtrace
test -v GITHUB_ACTIONS && DOCKER_SHELLOPTS=xtrace

if test -n "$DEBUG"; then
    LOG=/dev/stdout
else
    LOG=$SCRIPT.log
fi


clean_name="$(basename "$SCRIPT")"
CONTAINER="backend-server-${clean_name%.*}"

# this function is used in a trap, so ignore SC2317
# shellcheck disable=SC2317
cleanup() {
    # ephemeral container deleted when stopped
    lxc stop "$CONTAINER"
}

trap cleanup EXIT INT

lxc launch "$TEST_IMAGE" "$CONTAINER" --quiet --ephemeral -c security.nesting=True
lxc exec "$CONTAINER" -- cloud-init status --wait

if test -z "${DEBUG:-}"; then
    # if we're not in debug mode, just copy files. This does not require shiftfs,
    # so works in GHA and on more systems.
    tar c . | lxc exec "$CONTAINER" -- tar x --one-top-level=$BACKEND_SERVER_DIR
    DEBIAN_FRONTEND=noninteractive
else
    # in debug mode, it is useful to have the project mounted in the the
    # container, and we use the awesome shiftfs to make the uids match up.
    lxc config device add "$CONTAINER" backend-server disk source="$PWD" path=$BACKEND_SERVER_DIR shift=true
    DEBIAN_FRONTEND=dialog
fi




lxc exec "$CONTAINER" -- cloud-init status --wait
# run test script
set +e # we handle the error manually
echo -n "Running $SCRIPT in $CONTAINER LXD container..."
lxc exec "$CONTAINER" \
    --env SHELLOPTS=${DOCKER_SHELLOPTS} --env TEST=true --env TEST_CONFIG=$BACKEND_SERVER_DIR/tests/config.env \
    --env DEBIAN_FRONTEND=$DEBIAN_FRONTEND \
    --cwd $BACKEND_SERVER_DIR -- "$SCRIPT" > "$LOG" 2>&1
success=$?

set -e
if test $success -eq 0; then
    echo "SUCCESS"
    if [ "$GITHUB_ACTIONS" = "true" ]; then
      echo "### $1 ###"
      cat "$LOG"
      echo "### $1 ###"
    fi
else
    echo "FAILED"
    if test -f "$LOG"; then
        echo "### $1 ###"
        if test -x "${CI:-}"; then
            echo "..."
            tail -20 "$LOG"
        else
            cat "$LOG"
        fi
        echo "### $1 ###"
    fi
fi

if test -n "$DEBUG"; then
    echo "Running bash inside container (container will be deleted on exit)"
    lxc exec "$CONTAINER" --env TEST=true --cwd $BACKEND_SERVER_DIR -- bash
fi

exit $success
