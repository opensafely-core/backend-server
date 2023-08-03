#!/bin/bash
set -euo pipefail

if test -z "$BACKEND_JUST"
then
  echo "Please specify your backend when running this file. For example:"
  echo "BACKEND_JUST=test-backend ./bootstrap.sh";
  exit 1
fi

echo "BACKEND_JUST=$BACKEND_JUST" > .env

# TODO: will this work on EMIS?
# Heavily based on https://just.systems/install.sh
archive="https://github.com/casey/just/releases/download/1.14.0/just-1.14.0-x86_64-unknown-linux-musl.tar.gz"
mkdir tmp
curl --proto =https --tlsv1.2 -sSfL $archive | tar -C tmp -xz
mv tmp/just /usr/local/bin
chmod 0755 /usr/local/bin/just

# TODO: this is confusingly similar to 'just install'
echo "Now run 'just manage'"
