export TESTS := `ls tests/install.sh tests/backends/*.sh`
export TEST := "true"
github_actions := env_var_or_default('GITHUB_ACTIONS', "false")
BACKEND_SERVER_DIR := env_var_or_default('BACKEND_SERVER_DIR', "/srv/backend-server")
# run-in-lxd.sh uses these env_vars
export DEBUG := env_var_or_default('DEBUG', "")
export GITHUB_ACTIONS := env_var_or_default('GITHUB_ACTIONS', "false")
set dotenv-load := true


default:
  @just --list

# lint some shellscripts
lint:
  shellcheck -x */*.sh services/*/*.sh services/jobrunner/bashrc bin/lsjobs run-in-lxd.sh build-lxd-image.sh

[private]
check:
  #!/bin/bash
  set -euo pipefail

  test $PWD = {{ BACKEND_SERVER_DIR }}* || { echo "You must run this from {{ BACKEND_SERVER_DIR }}"; exit 1; }

  if test -z $BACKEND_JUST
  then
    echo "BACKEND_JUST is not set in .env";
    exit 1
  fi
  if [[ $BACKEND_JUST == *"-backend"* ]]; then
    echo "Please shorten BACKEND_JUST (i.e. 'test' instead of 'test-backend')"
    exit 1
  fi
  if test ! -e backends/$BACKEND_JUST
  then
    echo "Backend 'backends/$BACKEND_JUST' does not exist in this repo"
    exit 1
  fi

# install required system packages
install-packages: check
  ./scripts/install_packages.sh

# install/update groups & system level configuration 
install: check
  ./scripts/install.sh


# report which backend configuration this justfile is using
whereami: check
  @echo "Your current backend is: $BACKEND_JUST"

update-users: check
  ./scripts/update-users.sh $BACKEND_JUST

install-jobrunner: check
  ./services/jobrunner/install.sh $BACKEND_JUST

install-release-hatch: check
  ./services/release-hatch/install.sh

install-osrelease: check
  ./services/osrelease/install.sh

install-collector: check
  ./services/collector/install.sh

# Update jobrunner to the specified commit_id & restart
update-jobrunner commit_id="HEAD": check
  ./services/jobrunner/bin/update-jobrunner.sh {{ commit_id }}

# install everything for a backend
manage: check
  @{{ just_executable() }} manage-$BACKEND_JUST

[private]
manage-emis: install update-users install-jobrunner install-release-hatch
  #!/bin/bash
  set -euo pipefail

  for f in /home/jobrunner/config/*.env; do
      # shellcheck disable=SC1090
      . "$f"
  done

  if test -z "${PRESTO_TLS_KEY_PATH:-}"; then
      echo "WARNING: PRESTO_TLS_KEY_PATH env var not defined"
  else
      test -e "${PRESTO_TLS_KEY_PATH:-}" ||  echo "WARNING: PRESTO_TLS_KEY_PATH=$PRESTO_TLS_KEY_PATH does not exist"
  fi
  if test -z "${PRESTO_TLS_CERT_PATH:-}"; then
      echo "WARNING: PRESTO_TLS_CERT_PATH env var not defined"
  else
      test -e "${PRESTO_TLS_CERT_PATH:-}" ||  echo "WARNING: PRESTO_TLS_CERT_PATH=$PRESTO_TLS_CERT_PATH does not exist"
  fi

[private]
manage-test: install-packages install update-users install-jobrunner install-release-hatch install-osrelease install-collector

[private]
manage-tpp: install-packages install update-users install-jobrunner install-release-hatch install-collector

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
