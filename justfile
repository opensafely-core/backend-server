export TESTS := `ls tests/install.sh tests/*-backend.sh`
export TEST := "true"
github_actions := env_var_or_default('GITHUB_ACTIONS', "false")
# run-in-lxd.sh uses this env_var
export DEBUG := env_var_or_default('DEBUG', "")

lint:
  shellcheck -x */*.sh jobrunner/bashrc

build: testuser-key build-test-image

build-test-image:
  #!/usr/bin/env bash
  set -euo pipefail

  test packages.txt -nt .test-image -o core-packages.txt -nt .test-image -o purge-packages.txt -nt .test-image -o build-lxd-image.sh -nt .test-image || exit 0
  time {{ if github_actions == "true" { "sudo" } else { "" } }} ./build-lxd-image.sh
  touch .test-image

testuser-key:
  #!/usr/bin/env bash
  set -euo pipefail

  test -e keys/testuser && exit 0
  ssh-keygen -t ed25519 -N "" -C testuser -f keys/testuser.key
  mv keys/testuser.key.pub keys/testuser

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

run_test target: build
  {{ if github_actions == "true" { "sudo" } else { "" } }} ./run-in-lxd.sh {{target}}

clean:
	rm -rf keys/testuser keys/testuser.key .test-image
