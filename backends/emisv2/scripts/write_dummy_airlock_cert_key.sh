#!/bin/bash

# services/airlock/install.sh enables and starts the airlock service, which
# pulls the image and starts airlock. It won't start properly if the airlock
# cert key file is missing altogether, but it will start if it's there, even
# if it's not valid. We add the file here so that we don't bake the key into
# the AMI, and we populate the real key on instance start (see cloud-init-emis/user-data)
set -euo pipefail

mkdir -p /home/opensafely/airlock/certs
echo "dummy-key-replaced-on-instance-launch" > /home/opensafely/airlock/certs/airlock.key

# set permissions; ownership will be handled in the airlock install script
chmod 600 /home/opensafely/airlock/certs/airlock.key
