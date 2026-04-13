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
* ./keys/$USER
  * public keys to add to ssh for $USER
* ./developers
  * developers GitHub account list. To be replaced by authenticated API call to
    job-server later, perhaps.
* ./tests
  * test scripts, run in docker container by makefile
* ./tests/run-in-lxd.sh
  * runner for above tests. Uses LXD to provide a VM-like environment to run scripts on.

## Testing

To run tests, we use LXD to provide and isolated VM-like environment. 

There are specific reasons we use LXD:
 - provides a VM like container on standard images, with systemd, sshd, etc, unlike docker.
 - can run nested docker containers easily
 - works in Github CI where we cannot have nested VMs

### Configuring LXD

You will need to have LXD installed and configured. This currently assumes an
Ubuntu host. Try their [First steps with LXD](https://documentation.ubuntu.com/lxd/en/latest/tutorial/first_steps/).

Don't forget to [configure your firewall](https://documentation.ubuntu.com/lxd/en/latest/howto/network_bridge_firewalld/) appropriately.

#### LXD Quickstart for ubuntu:

```
sudo snap install lxd --channel=5.21/stable
sudo usermod -aG lxd "$USER"
newgrp lxd
sudo lxd init --auto
```

This default setup is fine for most developers, if a bit slow


If you have zfs on your host, and you want faster lxd performance you can instead do:

```
sudo lxd init --auto --storage-backend=zfs
```

If you get errors about missing tools, you maybe on more a recent HWE kernel, and need a more recent lxd:

```
sudo snap refresh lxd --channel=6/stable
```

#### Firewall setup for LXD

To configure ufw to allow network traffic to/from LXD instances, run:

```
sudo ufw allow in on lxdbr0
sudo ufw route allow in on lxdbr0
sudo ufw route allow out on lxdbr0
```

If you also run Docker on the host, Docker can set the global `FORWARD` policy
to `DROP`, which breaks network access for LXD instances. The LXD docs
recommend enabling IPv4 forwarding before Docker starts and making it
persistent across reboots:

```
echo "net.ipv4.conf.all.forwarding=1" | sudo tee /etc/sysctl.d/99-forwarding.conf
sudo systemctl restart systemd-sysctl
```

### Running tests

To run tests:

    just test

To run specific tests (tab completes)

    just tests/run_test tests/$TEST

If you specify DEBUG=1, then you will be dropped into a shell inside the docker
container after the tests has run, e.g. 

    DEBUG=1 just tests/run_test tests/$TEST 

Note: `DEBUG=1` uses a shifted bind mount for a nicer edit/debug cycle. Normal
test runs do not rely on that mount path.
