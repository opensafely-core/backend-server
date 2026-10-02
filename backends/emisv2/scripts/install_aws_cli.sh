#!/bin/bash
# Install emis-specific packages.
set -euo pipefail

# awscli
# Note: we probably don't want to install like this
apt-get install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"

unzip /tmp/awscliv2.zip -d /tmp

/tmp/aws/install

rm -rf /tmp/aws
rm /tmp/awscliv2.zip
