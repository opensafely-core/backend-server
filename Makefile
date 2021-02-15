TESTS ?= $(shell ls tests/*.sh)
TEST_IMAGE=backend-server-test
export TEST=true


# disable default rules
.SUFFIXES:


.PHONY: lint
lint:
	shellcheck */*.sh


# list of all github users mentioned in the repo
.gh-users: developers */researchers */reviewers
	cat $^ | sort | uniq | grep -v '^#' > $@


# fetch and cache gh keys for users, so we can avoid ratelimits when testing locally
.ssh-key-cache: .gh-users
	mkdir -p .ssh-key-cache
	for u in $$(cat .gh-users); do ssh-import-id gh:$$u -o $@/$$u; done


# proxy file to track image needing to be rebuilt
.test-image: packages.txt Dockerfile
	$(MAKE) test-image


.PHONY: test-image
test-image:
	docker build . -t $(TEST_IMAGE) && touch .test-image


# run all tests
.PHONY: test
test: $(TESTS)


# run specific test
.PHONY: $(TESTS)
$(TESTS): .test-image | .ssh-key-cache
	./run-in-docker.sh $@


clean:
	rm -rf .gh-users .ssh-key-cache
