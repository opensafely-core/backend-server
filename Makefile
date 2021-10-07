# TESTS ?= $(shell ls tests/*.sh)
TESTS="tests/test-backend.sh"
BACKENDS=tpp-backend emis-backend
TEST_IMAGE=backend-server-test
CACHE_DIR=.ssh-key-cache
export TEST=true


# disable default rules
.SUFFIXES:


.PHONY: lint
lint:
	shellcheck -x */*.sh jobrunner/bashrc


keys/testuser:
	ssh-keygen -t ed25519 -N "" -C testuser -f keys/testuser.key
	mv keys/testuser.key.pub keys/testuser


.PHONY: test-image
test-image: .test-image


# proxy file to track image needing to be rebuilt
.test-image: packages.txt core-packages.txt purge-packages.txt build-lxd-image.sh
	time ./build-lxd-image.sh
	touch $@


# run all tests
.PHONY: test
test: $(TESTS)


# run specific test
.PHONY: $(TESTS)
$(TESTS): .test-image keys/testuser
	@test "$$GITHUB_ACTIONS" = "true" && echo "::group::$@" || true
	./run-in-lxd.sh $@
	@test "$$GITHUB_ACTIONS" = "true" && echo "::endgroup::" || true

clean:
	rm -rf .gh-users .ssh-key-cache .test-image

