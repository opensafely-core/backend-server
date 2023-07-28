export TESTS := `ls tests/install.sh tests/*-backend.sh`
export TEST := "true"
github_actions := env_var_or_default('GITHUB_ACTIONS', "false")
# run-in-lxd.sh uses this env_var
export DEBUG := env_var_or_default('DEBUG', "")

lint:
  shellcheck -x */*.sh jobrunner/bashrc

build:
  make test-image keys/testuser

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
  make clean
