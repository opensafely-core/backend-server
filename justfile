lint:
	shellcheck -x */*.sh jobrunner/bashrc

build:
  make test-image keys/testuser

test:
  make test

clean:
  make clean
