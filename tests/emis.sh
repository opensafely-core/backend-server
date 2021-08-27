#!/bin/bash
set -euo pipefail

# we currently can not install new packages in EMIS, as we don't have access to
# ubuntu archives. The packages core-packages.txt are already installed.
# 
# To simulate this in these tests, we uninstall packages.txt from the test
# docker image, to make sure everything still works
set +u
sed 's/^#.*//' packages.txt | xargs apt-get remove -y
apt-get autoremove -y
set -u

# ok, lets go!

./emis-backend/manage.sh
# run again to check for idempotency
./emis-backend/manage.sh

# Some assertions
grep -q SimonDavy@OPENCORONA ~bloodearnest/.ssh/authorized_keys

# run hatch tests
./tests/check-hatch
