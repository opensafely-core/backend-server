export TESTS := `ls tests/install.sh tests/*-backend.sh`
export TEST := "true"
github_actions := env_var_or_default('GITHUB_ACTIONS', "false")
# run-in-lxd.sh uses these env_vars
export DEBUG := env_var_or_default('DEBUG', "")
export GITHUB_ACTIONS := env_var_or_default('GITHUB_ACTIONS', "false")

default:
  @just --list

# lint some shellscripts
lint:
  shellcheck -x */*.sh services/*/*.sh services/jobrunner/bashrc bin/lsjobs run-in-lxd.sh build-lxd-image.sh

install:
  ./scripts/install.sh

manage-test-backend: install
  #!/bin/bash
  set -euo pipefail

  ./scripts/update-users.sh developers
  ./services/jobrunner/install.sh test-backend
  ./release-hatch/install.sh
  ./services/osrelease/install.sh
  ./services/collector/install.sh

manage-tpp-backend: install
  #!/bin/bash
  set -euo pipefail

  ./scripts/update-users.sh developers tpp-backend/researchers
  ./services/jobrunner/install.sh tpp-backend
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
