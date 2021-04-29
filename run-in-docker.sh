#!/bin/bash
# Run an ubuntu docker "VM", then run the passed command inside it.  The
# container is deleted when this script exits.
#
# Run with DEBUG=1 to run a shell inside the container after running your
# script
# 
# Note: you may need to first build the test image before you can manually run
# this script:
#     
#     make test-image
#
set -euo pipefail
SCRIPT=$1
LOG=$SCRIPT.log
TEST_IMAGE=backend-server-test
DEBUG=${DEBUG:-}
TRACE=${TRACE:-}
DOCKER_SHELLOPTS=

test -n "$TRACE" && DOCKER_SHELLOPTS=xtrace

if test -n "$DEBUG"; then
    LOG=/dev/stdout
else
    LOG=$SCRIPT.log
fi

# Launch a container running systemd
CONTAINER="$(
    docker run -d --rm \
               --cap-add SYS_ADMIN --tmpfs /tmp --tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
               -v "$PWD:/tests" "$TEST_IMAGE"
)"

trap 'docker rm -f $CONTAINER >/dev/null' EXIT

# run test script
set +e # we handle the error manually
echo -n "Running $1 in container..."
docker exec -i -e SHELLOPTS=${DOCKER_SHELLOPTS} -e TEST=true -w /tests "$CONTAINER" "$SCRIPT" > "$LOG" 2>&1
success=$?

set -e
if test $success -eq 0; then
    echo "SUCCESS"
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
    docker exec -it -e TEST=true -w /tests "$CONTAINER" bash
fi

exit $success
