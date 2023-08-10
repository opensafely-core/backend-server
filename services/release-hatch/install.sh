#!/bin/bash
set -euo pipefail

DIR=~jobrunner/release-hatch
SSL_CERT=$DIR/certs/release-hatch.crt
SSL_KEY=$DIR/certs/release-hatch.key
SYSTEM_CERTS=/usr/local/share/ca-certificates/release-hatch

mkdir -p $DIR
cp -a ./services/release-hatch/* "$DIR"

if ! test -e $SSL_KEY -a -e $SSL_CERT; then
    # shellcheck disable=SC1090
    source <(cat /srv/jobrunner/environ/*.env)

    # clean http:// and ports
    HOSTNAME="$(echo "$RELEASE_HOST" | cut -d'/' -f3 | cut -d':' -f1)"

    mkdir -p "$(dirname $SSL_CERT)"

    # generate a self signed certificate
    openssl req -x509 -newkey ed25519 -keyout $SSL_KEY -out $SSL_CERT -sha256 -days 365 -nodes \
	    -subj "/C=GB/O=OpenSAFELY/CN=$HOSTNAME/emailAddress=tech@opensafely.org" \
	    -addext "subjectAltName = DNS:$HOSTNAME"

    # ensure self signed is trusted by this machine
    mkdir -p $SYSTEM_CERTS
    ln -sf $SSL_CERT $SYSTEM_CERTS/
    update-ca-certificates
fi

chown -R jobrunner:jobrunner "$DIR"
chmod -R go-rwx "$DIR"

systemctl enable "$DIR/release-hatch.service"
systemctl enable "$DIR/release-hatch.timer"
systemctl start release-hatch.timer
systemctl start release-hatch.service || { journalctl -u release-hatch.service; exit 1; }
