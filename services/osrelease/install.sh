#!/bin/bash
set -euo pipefail

DIR=~jobrunner/osrelease
SRC_DIR=services/osrelease
CODE=$DIR/code
VENV=$DIR/venv
WHEELS=$DIR/wheels
CONFIG=$DIR/config.py

mkdir -p $DIR
test -d $CODE || git clone https://github-proxy.opensafely.org/opensafely-core/output-publisher $CODE
test -d $WHEELS || git clone https://github-proxy.opensafely.org/opensafely-core/output-publisher-wheels $WHEELS
test -f $CONFIG || cp $SRC_DIR/config-template.py $CONFIG

if ! test -d $VENV; then
    python3 -m venv $VENV
    $VENV/bin/pip install --no-index --find-links $WHEELS -r $CODE/requirements.prod.txt
    $VENV/bin/pip install -e $CODE
fi

# reviewers group need to run osrelease, so they need to be able to read
# osrelease code and config
chmod -R g+r $DIR
chown -R jobrunner:reviewers $DIR
# we need to be able to run the executable inside jobrunner user.
chmod a+rx ~jobrunner

# update the deploy script
cp $SRC_DIR/deploy.sh $DIR/deploy.sh

# update the entrypoint executable
cp $SRC_DIR/osrelease.sh /usr/local/bin/osrelease
# ensure correct owndership
chown jobrunner:reviewers /usr/local/bin/osrelease
