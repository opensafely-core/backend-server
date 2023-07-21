export TESTS := `ls tests/install.sh tests/*-backend.sh`
export TEST := "true"
github_actions := env_var_or_default('GITHUB_ACTIONS', "false")

lint:
  shellcheck -x */*.sh jobrunner/bashrc

build:
  make test-image keys/testuser

test:
  for i in $TESTS; do just run_test $i; done

run_test target: build
  # group output by target when displaying in Github Actions
  {{ if github_actions == "true" { "echo -n \"::group::\"" + target  } else { "" } }}
  {{ if github_actions == "true" { "sudo" } else { "" } }} ./run-in-lxd.sh {{target}}
  {{ if github_actions == "true" { "echo \"::endgroup::\"" } else { "" } }}

clean:
  make clean
