lint:
	shellcheck -x */*.sh jobrunner/bashrc

build:
  make test-image
  make keys/testuser

test:
  make test

clean:
  make clean
