export TESTS := `ls tests/install.sh tests/*-backend.sh`
export TEST := "true"
github_actions := env_var_or_default('GITHUB_ACTIONS', "false")
# run-in-lxd.sh uses these env_vars
export DEBUG := env_var_or_default('DEBUG', "")
export GITHUB_ACTIONS := env_var_or_default('GITHUB_ACTIONS', "false")
set dotenv-load := true

default:
  @just --list

# lint some shellscripts
lint:
  shellcheck -x */*.sh services/*/*.sh services/jobrunner/bashrc bin/lsjobs run-in-lxd.sh build-lxd-image.sh

# basic initial install for backends - this should be renamed to something after bootstrap? or split into 3?
install:
  ./scripts/install.sh

[private]
check_backend_set:
  #!/bin/bash
  set -euo pipefail

  if test -z $BACKEND_JUST
  then
    echo "BACKEND_JUST is not set in .env";
    exit 1
  fi
  if test ! -e $BACKEND_JUST
  then
    echo "Backend $BACKEND_JUST does not exist in this repo"
    exit 1
  fi

# report which backend configuration this justfile is using
whereami: check_backend_set
  @echo "Your current backend is: $BACKEND_JUST"

update-users: check_backend_set
  @{{ just_executable() }} update-users-$BACKEND_JUST

[private]
update-users-test-backend:
  ./scripts/update-users.sh developers

[private]
update-users-tpp-backend:
  ./scripts/update-users.sh developers tpp-backend/researchers

install-jobrunner: check_backend_set
  ./services/jobrunner/install.sh $BACKEND_JUST

manage: check_backend_set
  @{{ just_executable() }} manage-$BACKEND_JUST

[private]
manage-test-backend: install update-users install-jobrunner
  #!/bin/bash
  set -euo pipefail

  ./release-hatch/install.sh
  ./services/osrelease/install.sh
  ./services/collector/install.sh

[private]
manage-tpp-backend: install update-users install-jobrunner
  #!/bin/bash
  set -euo pipefail

  ./release-hatch/install.sh
  ./services/collector/install.sh

# build resources required to run tests
build: testuser-key build-test-image

# build lxd image for tests
build-test-image:
  #!/usr/bin/env bash
  set -euo pipefail

  test packages.txt -nt .test-image -o core-packages.txt -nt .test-image -o purge-packages.txt -nt .test-image -o build-lxd-image.sh -nt .test-image || exit 0
  time {{ if github_actions == "true" { "sudo" } else { "" } }} ./build-lxd-image.sh
  touch .test-image

# create ssh key for tests
testuser-key:
  #!/usr/bin/env bash
  set -euo pipefail

  test -e keys/testuser && exit 0
  ssh-keygen -t ed25519 -N "" -C testuser -f keys/testuser.key
  mv keys/testuser.key.pub keys/testuser

# run all tests
test: build
  #!/usr/bin/env bash
  set -euo pipefail

  for i in $TESTS;
  do
    # group output by target when displaying in Github Actions
    {{ if github_actions == "true" { "echo \"::group::\"$i"  } else { "" } }}
    {{ just_executable() }} run_test "$i"
    {{ if github_actions == "true" { "echo \"::endgroup::\"" } else { "" } }}
  done

# run a specific test
run_test target: build
  {{ if github_actions == "true" { "sudo -E" } else { "" } }} ./run-in-lxd.sh {{target}}

# remove temporary files relating to tests
clean:
	rm -rf keys/testuser keys/testuser.key .test-image
