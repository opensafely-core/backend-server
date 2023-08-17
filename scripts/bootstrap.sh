#!/bin/bash
set -euo pipefail

BACKEND_SERVER_DIR="${BACKEND_SERVER_DIR:-/srv/backend-server}"

if test "$PWD" != "$BACKEND_SERVER_DIR"; then
  echo "You must run this script from a checkout of backend-server located at $BACKEND_SERVER_DIR"
  exit 1
fi

if test -z "$1"
then
  echo "Please specify your backend when running this file. For example:"
  echo "$0 my_backend";
  exit 1
fi

echo "BACKEND_JUST=$1" > .env

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
  echo "Installing just in /usr/local/bin/just"
  cp "$PWD/bin/just-1.14.0-x86_64-unknown-linux-musl" /usr/local/bin/just
  chmod 0755 /usr/local/bin/just
else
  echo "Only linux-gnu is currently supported for installing 'just'."
  echo "Please install 'just' manually."
  exit 1
fi

# TODO: this is confusingly similar to 'just install'
echo "Now run 'just manage'"
