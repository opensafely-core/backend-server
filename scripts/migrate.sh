#!/bin/bash
set -euxo pipefail

systemctl stop jobrunner

mkdir -m 700 ~opensafely/config
mkdir -m 700 ~opensafely/jobrunner

cp -r /srv/jobrunner/environ/*.env ~opensafely/config/
cp -r /srv/jobrunner/code/workdir ~opensafely/jobrunner/workdir

chown -R opensafely:opensafely ~opensafely/jobrunner ~opensafely/config
chmod -R 600 ~opensafely/config/*.env

echo "Please verify contents of ~opensafely/config/ and remove /srv/jobrunner/environ/ if correct"

sed -i 's#/srv/jobrunner/bashrc#~/.bashrc-opensafely#g' ~opensafely/.bashrc

# remove old bashrc(s)
rm -f /srv/jobrunner/bashrc
rm -f /home/jobrunner/jobrunner/bashrc
