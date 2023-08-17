#!/bin/bash
set -euo pipefail

./scripts/bootstrap.sh test

# Test install scripts
./scripts/install.sh
./scripts/update-users.sh developers

# run again to test idempotency
./scripts/install.sh

. "tests/utils.sh"

# add test user that we know the key for
developers=tests/developers ./scripts/update-users.sh test

# set password so ssh does not bounce us
echo 'testuser:10f9afsasva21d%' | chpasswd

# test sshd config
sshd -T > /tmp/ssh-config
strip-comments etc/opensafely/ssh.conf | while read -r line; do
    assert "ssh: $line is set" grep -qi "$line" /tmp/ssh-config
done

# needed to be able to log in before fully booted in CI tests for some reason
rm -f /run/nologin /etc/nologin

# test can actually ssh
assert "ssh: can log in" ssh "testuser@localhost" -i keys/testuser.key -o StrictHostKeyChecking=no /bin/true

# test /etc/profile
(
set +u
. /etc/profile
set -u
assert "env var: TMOUT is set" test "$TMOUT" == "900"
)


# create test user for password checking
useradd testpwuser --create-home --shell /bin/bash

# helper function because chpasswd does not error correctly
test-password() {
    # shellcheck disable=SC2317
    ! echo "testpwuser:$1" | chpasswd 2>&1 | grep -q "BAD PASSWORD" 
}

assert-fails "password: bad password rejected" test-password simple
assert "password: password accepted " test-password 'a$#sdad0822daf0flASD'

# test sudo
useradd testsudouser --create-home --shell /bin/bash

assert-fails "sudo: not in developers group" su - testsudouser -c 'sudo ls /root'

usermod -a -G developers testsudouser
# sudo config works
assert-fails "sudo: no password set" su - testsudouser -c 'sudo ls /root'

password='V4al1d-p4##0rd'
echo "testsudouser:$password" | chpasswd
echo "$password" | assert "sudo: password sudo works" su - testsudouser -c 'sudo -S ls /root'

actual_user=$(head -1 developers)
assert "users: directory permissions" test "$(stat -c '%a' "/home/$actual_user")" == "750"

# shellcheck disable=SC2154
exit "$success"
