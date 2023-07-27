BACKENDS=tpp-backend emis-backend
export TEST=true


# disable default rules
.SUFFIXES:


.PHONY: test-image
test-image: .test-image


# proxy file to track image needing to be rebuilt
.test-image: packages.txt core-packages.txt purge-packages.txt build-lxd-image.sh
	time ./build-lxd-image.sh
	touch $@

