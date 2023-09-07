#!/bin/bash
set -euo pipefail

systemctl stop jobrunner

mkdir -m 700 ~jobrunner/config
mkdir -m 700 ~jobrunner/jobrunner

cp -r /srv/jobrunner/environ/*.env ~jobrunner/config/
cp -r /srv/jobrunner/code/workdir ~jobrunner/jobrunner/workdir

chown -R jobrunner:jobrunner ~jobrunner/jobrunner ~jobrunner/config
chmod -R 600 ~jobrunner/config/*.env

sed -i 's#/srv/jobrunner/bashrc#~/jobrunner/bashrc#g' ~/.bashrc
