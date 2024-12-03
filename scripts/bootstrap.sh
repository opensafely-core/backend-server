#!/bin/bash
set -euo pipefail

BACKEND=${1:-}

if test -z "$BACKEND"; then
    echo "You must specify a backend to bootstrap"
    exit 1
fi

BACKEND_SERVER_DIR="${BACKEND_SERVER_DIR:-/srv/backend-server}"

if test "$EUID" -ne 0; then
  echo "Please run as root"
  exit 1
fi

if test "$PWD" != "$BACKEND_SERVER_DIR"; then
  echo "You must run this script from a checkout of backend-server located at $BACKEND_SERVER_DIR"
  exit 1
fi

if test -z "$BACKEND"
then
  echo "Please specify your backend when running this file. For example:"
  echo "$0 my_backend";
  exit 1
fi

# put in .env to ensure `just` has access to it
echo "BACKEND=$BACKEND" > .env

# also put it in the default profile so everything else has access to it
mkdir -p /etc/opensafely/profile.d
BACKEND_PROFILE=/etc/opensafely/profile.d/backend.sh
grep -q "$BACKEND" $BACKEND_PROFILE 2>/dev/null || printf "BACKEND=%s\nexport BACKEND" "$BACKEND" >> $BACKEND_PROFILE
ln -sf $BACKEND_PROFILE /etc/profile.d/backend.sh

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
  echo "Installing just in /usr/local/bin/just"
  install -m 755 "$PWD/bin/just-1.14.0-x86_64-unknown-linux-musl" /usr/local/bin/just
  just --completions bash > /etc/bash_completion.d/just
  chmod 755 /etc/bash_completion.d/just
else
  echo "Only linux-gnu is currently supported for installing 'just'."
  echo "Please install 'just' manually."
  exit 1
fi

# TODO: this is confusingly similar to 'just install'
echo "Now run 'just manage'"
