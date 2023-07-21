#!/bin/bash

# final success or failure
success=0

# strip comments and blank lines from a file
strip-comments() {
    sed -e '/^\s*$/d' -e '/^\s*#.*$/d' "$1"
}

assert() {
  local desc=$1
  local log
  log=$(mktemp)
  shift;
  if "$@" >"$log" 2>&1; then
    echo "PASS: $desc"
  else
    echo "FAIL: $desc"
    cat "$log"
    success=1
  fi
}

assert-fails() {
  local desc=$1
  local log
  log=$(mktemp)
  shift;
  if "$@" >"$log" 2>&1; then
    echo "FAIL: $desc"
    cat "$log"
    success=1
  else
    echo "PASS: $desc"
  fi
}

