BACKENDS=tpp-backend emis-backend
CACHE_DIR=.ssh-key-cache
export TEST=true


# disable default rules
.SUFFIXES:


keys/testuser:
	ssh-keygen -t ed25519 -N "" -C testuser -f keys/testuser.key
	mv keys/testuser.key.pub keys/testuser


.PHONY: test-image
test-image: .test-image


# proxy file to track image needing to be rebuilt
.test-image: packages.txt core-packages.txt purge-packages.txt build-lxd-image.sh
	time ./build-lxd-image.sh
	touch $@


clean:
	rm -rf .gh-users .ssh-key-cache .test-image

