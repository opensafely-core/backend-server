#!/bin/bash
# load config into this shell so we can just run stuff
set -a
# shellcheck disable=SC1090
for f in /home/opensafely/config/*.env; do
    . "$f"
done
set +a

# let opensafely user use the opensafely commands and scripts easily
export PYTHONPATH=/srv/opensafely/code:/srv/opensafely/lib
export PATH=$PATH:/srv/opensafely/bin:/srv/opensafely/code/scripts

cat << EOF
You have logged into the shared opensafely account for managing the jobrunner
and other services.

Current status:

systemctl status -n0 jobrunner
$(systemctl status -n0 jobrunner)


********************************************
** Nb. these paths changed September 2023 **
********************************************

Environment variables have been set from /home/opensafely/config/*.env"

Code: /home/opensafely/jobrunner/code
Deps: /home/opensafely/jobrunner/lib
Config: /home/opensafely/config

Medium privacy files are at $MEDIUM_PRIVACY_STORAGE_BASE
High privacy files are at $HIGH_PRIVACY_STORAGE_BASE

To restart:

    sudo systemctl restart jobrunner

Please consult ~/playbook.md for operational documentation.
EOF
