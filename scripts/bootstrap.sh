#!/bin/bash

# TODO: won't work on EMIS
archive="https://github.com/casey/just/releases/download/1.14.0/just-1.14.0-x86_64-unknown-linux-musl.tar.gz"
mkdir tmp
curl --proto =https --tlsv1.2 -sSfL $archive | tar -C tmp -xz
mv tmp/just /usr/local/bin
chmod 0755 /usr/local/bin/just
