#!/bin/bash
# load config into this shell so we can just run stuff
set -a
# shellcheck disable=SC1090
for f in /home/jobrunner/config/*.env; do
    . "$f"
done
set +a

# let jobrunner user use the jobrunner commands and scripts easily
export PYTHONPATH=/home/jobrunner/jobrunner/code:/home/jobrunner/jobrunner/lib
export PATH=$PATH:/home/jobrunner/bin:/home/jobrunner/jobrunner/code/scripts

cat << EOF
You have logged into the shared jobrunner account for managing the jobrunner service.

Current status:

systemctl status -n0 jobrunner
$(systemctl status -n0 jobrunner)


********************************************
** Nb. these paths changed September 2023 **
********************************************

Environment variables have been set from /home/jobrunner/config/*.env"

Code: /home/jobrunner/jobrunner/code
Deps: /home/jobrunner/jobrunner/lib
Config: /home/jobrunner/config

Medium privacy files are at $MEDIUM_PRIVACY_STORAGE_BASE
High privacy files are at $HIGH_PRIVACY_STORAGE_BASE

To restart:

    sudo systemctl restart jobrunner

Please consult ~/playbook.md for operational documentation.
EOF
