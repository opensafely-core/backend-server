#!/bin/bash
# Set up the job-runner service
set -euo pipefail
BACKEND_DIR=$1

# set default file creation permission for this script be 640 for files and 750
# for directories
umask 027

DIR=/srv/jobrunner

./scripts/jobrunner-config.sh "$BACKEND_DIR"

secrets_env="$DIR/environ/02_secrets.env"

# ensure we have a checkout of job-runner and dependencies
test -d $DIR/code || git clone https://github-proxy.opensafely.org/opensafely-core/job-runner $DIR/code
test -d $DIR/lib || git clone https://github-proxy.opensafely.org/opensafely-core/job-runner-dependencies $DIR/lib

# service configuration
mkdir -p $DIR/bin
cp jobrunner/bin/* /srv/jobrunner/bin/


# load config
set -a
# shellcheck disable=SC1090
for f in "$DIR"/environ/*.env; do
    # shellcheck disable=1090
    . "$f"
done
set +a;

# set up some nice helpers for when we su into the shared jobrunner user
cp jobrunner/bashrc $DIR/bashrc
chmod 644 $DIR/bashrc
test -f ~jobrunner/.bashrc || touch ~jobrunner/.bashrc
grep -q "jobrunner/bashrc" ~jobrunner/.bashrc || echo 'test -f /srv/jobrunner/bashrc && . /srv/jobrunner/bashrc' >> ~jobrunner/.bashrc

# update playbook
cp jobrunner/playbook.md /srv/jobrunner/playbook.md
ln -sf "/srv/jobrunner/playbook.md" ~jobrunner/playbook.md

# clean up old playbook if present
rm -f /srv/playbook.md

# ensure file ownership and permissions
chown -R jobrunner:jobrunner /srv/jobrunner
chmod 0600 $secrets_env
chmod 0700 $DIR/secret
find $DIR/secret -type f -exec chmod 0600 {} \;

# set up systemd service
# Note: do this *after* permissions have been set on the /srv/jobrunner properly
cp jobrunner/jobrunner.service /etc/systemd/system/
cp jobrunner/jobrunner.sudo /etc/sudoers.d/jobrunner

# backend specific unit overrides
test -d "$BACKEND_DIR/jobrunner.service.d" && cp -Lr "$BACKEND_DIR/jobrunner.service.d" /etc/systemd/system/

systemctl enable --now jobrunner
