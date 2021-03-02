#!/bin/bash
# Set up the job-runner service
set -euo pipefail

DIR=/srv/osrelease
mkdir -p $DIR
# ensure we have a checkout of job-runner and dependencies
test -d $DIR/code || git clone https://github.com/opensafely-core/output-publisher $DIR/code
mkdir -p $DIR/environ

secrets_env="$DIR/environ/config.env"
test -f $secrets_env || cp osrelease/secrets-template.env $secrets_env

# reviewers group need to run osrelease, so they need to be able to read
# osrelease code and config
chown -R root:reviewers $DIR
find $DIR -type f -exec chmod 640 {} \;

# install for all users
pip3 install --system -e $DIR/code
