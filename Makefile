TESTS ?= $(shell ls tests/*.sh)
# can override in environment
RATELIMITED ?= false
TEST_IMAGE=backend-server-test

# disable default rules
.SUFFIXES:


.PHONY: lint
lint:
	shellcheck */*.sh


.PHONY: test-image
test-image:
	docker build . -t $(TEST_IMAGE) && touch .test-image


# file proxy for when the image was last built
.test-image: packages.txt Dockerfile
	$(MAKE) test-image


.PHONY: test
test: $(TESTS)


.PHONY: $(TESTS)
$(TESTS): .test-image
	tests/run $@
