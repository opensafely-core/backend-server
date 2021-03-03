TESTS ?= $(shell ls tests/*.sh)
BACKENDS=tpp-backend emis-backend
TEST_IMAGE=backend-server-test
CACHE_DIR=.ssh-key-cache
export TEST=true


# disable default rules
.SUFFIXES:


.PHONY: lint
lint:
	shellcheck */*.sh jobrunner/bashrc


# list of all github users mentioned in the repo
.gh-users: developers */researchers */reviewers
	cat $^ | sort | uniq | grep -v '^#' > $@

# fetch and cache gh keys for users, so we can avoid ratelimits when testing locally
$(CACHE_DIR)/updated: .gh-users 
	mkdir -p $(CACHE_DIR)
	for u in $$(cat .gh-users); do ssh-import-id gh:$$u -o $(CACHE_DIR)/$$u; done
	touch $@


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
$(TESTS): .test-image $(CACHE_DIR)/updated
	./run-in-docker.sh $@


# create a backend and drop you into a shell on it
.PHONY: $(BACKENDS)
$(BACKENDS): export VMNAME=$@
$(BACKENDS): $(CACHE_DIR)/updated
	./run-in-vm.sh $@/manage.sh


clean:
	rm -rf .gh-users .ssh-key-cache
