# Development Overview

Directory layout:

* ./scripts
  * various bash scripts to perform specific actions, designed to be idempotent
* ./etc
  * system configuration files/templates
* ./backends/
  * scripts and config for supported backends
* ./backends/emis
  * scripts and config for EMIS backend
* ./backends/nhsd
  * scripts and config for NHSD backend
* ./backends/test
  * scripts and config for our test backend
* ./backends/tpp
  * scripts and config for TPP backends
* ./emis-access
  * scripts for managing emis-access VM
* ./services/jobrunner
  * scripts and config templates for jobrunner
* ./services/osrelease
  * scripts and config templates for osrelease
* ./keys/$USER
  * public keys to add to ssh for $USER
* ./developers
  * developers gh account list. To be replaced by authenticated API call to
    job-server later, perhaps.
* ./tests
  * test scripts, run in docker container by makefile
* ./run-in-lxd.sh
  * runner for above tests. Uses LXD to provide a VM-like environment to run scripts on.

## Testing

To run tests, we use LXD to provide and isolate VM-like environment. You will
need to have LXD installed and configured, and `shiftfs` enabled. Currently,
this probably only works on Ubuntu.

https://linuxcontainers.org/lxd/getting-started-cli/

Quickstart for ubuntu:

```
snap install lxd --classic
sudo snap set lxd shiftfs.enable=true
sudo lxd init --auto
```

To run tests:

    just test

To run specific tests (tab completes)

    just run_test tests/$TEST

If you specify DEBUG=1, then you will be dropped into a shell inside the docker
container after the tests has run, e.g. 

    DEBUG=1 just run_test tests/$TEST 
