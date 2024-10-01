# Development Overview

Directory layout:

* ./scripts
  * various bash scripts to perform specific actions, designed to be idempotent
* ./etc
  * system configuration files/templates
* ./backends/
  * scripts and config for supported backends
* ./backends/test
  * scripts and config for our test backend
* ./backends/tpp
  * scripts and config for TPP backends
* ./services/jobrunner
  * scripts and config templates for jobrunner
* ./services/osrelease
  * scripts and config templates for osrelease
* ./keys/$USER
  * public keys to add to ssh for $USER
* ./developers
  * developers GitHub account list. To be replaced by authenticated API call to
    job-server later, perhaps.
* ./backends/*/researchers
  * researchers GitHub account list.
* ./backends/*/reviewers
  * reviewers GitHub account list.
* ./tests
  * test scripts, run in docker container by makefile
* ./tests/run-in-lxd.sh
  * runner for above tests. Uses LXD to provide a VM-like environment to run scripts on.

## Testing

To run tests, we use LXD to provide and isolate VM-like environment. 

### Configuring LXD

You will need to have LXD installed and configured, and `shiftfs` enabled. Currently,
this probably only works on Ubuntu. Try their [First steps with LXD](https://documentation.ubuntu.com/lxd/en/latest/tutorial/first_steps/). 

Don't forget to [configure your firewall](https://documentation.ubuntu.com/lxd/en/latest/howto/network_bridge_firewalld/) appropriately.

#### LXD Quickstart for ubuntu:

```
snap install lxd --classic
sudo snap set lxd shiftfs.enable=true
sudo lxd init --auto
```

### Running tests

To run tests:

    just test

To run specific tests (tab completes)

    just tests/run_test tests/$TEST

If you specify DEBUG=1, then you will be dropped into a shell inside the docker
container after the tests has run, e.g. 

    DEBUG=1 just tests/run_test tests/$TEST 
