export TESTS := `ls tests/install.sh tests/*-backend.sh`
export TEST := "true"
github_actions := env_var_or_default('GITHUB_ACTIONS', "false")
# run-in-lxd.sh uses this env_var
export DEBUG := env_var_or_default('DEBUG', "")

lint:
  shellcheck -x */*.sh jobrunner/bashrc

build: testuser-key
  make test-image 

testuser-key:
  #!/usr/bin/env bash
  test -e keys/testuser && exit 0
  ssh-keygen -t ed25519 -N "" -C testuser -f keys/testuser.key
  mv keys/testuser.key.pub keys/testuser

test:
  #!/usr/bin/env bash
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
