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

# awkwardly, to test EMIS release-hatch, we need to release-hatch on port 8001
# rather than 443, because of SSH tunnelling shenanagins run release-hatch

docker-compose -f ~jobrunner/release-hatch/docker-compose.yaml stop release-hatch
docker-compose -f ~jobrunner/release-hatch/docker-compose.yaml run -d -p 8001:8001 release-hatch

# tests
./tests/check-release-hatch
