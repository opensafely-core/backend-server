#!/bin/bash

# services/airlock/install.sh enables and starts the airlock service, which
# pulls the image and starts airlock. It won't start properly if the airlock
# cert key file is missing altogether, but it will start if it's there, even
# if it's not valid. We add the file here so that we don't bake the key into
# the AMI, and we rerun this script on instance start (see cloud-init-emis/user-data)
# with the real key
set -euo pipefail

AIRLOCK_CERT_KEY="${1:-dummy-key-replaced-on-instance-start}"

mkdir -p /home/opensafely/airlock/certs
printf '%b\n' "$AIRLOCK_CERT_KEY" > /home/opensafely/airlock/certs/airlock.key

# set permissions; ownership will be handled in the airlock install script
chmod 600 /home/opensafely/airlock/certs/airlock.key
