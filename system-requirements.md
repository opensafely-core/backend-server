# OpenSAFELY Backend System Requirements

## Base System

The OpenSAFELY backend is designed and tested to run on an Ubuntu 22.04 LTS VM.

This should have access to an appropriate Ubuntu archive mirror, and be
configured to apply security updates automatically.


## Dependencies

The explicit list can be found in [core-packages.txt](core-packages.txt).


## Services

The are currently four services, installed and run by the `opensafely` user

### RAP agent

This lives in ~opensafely/jobrunner.

This service does not listen on any port, but regularly initiates requests to the
OpenSAFELY platform, to request new jobs and to publish job statuses.  It also
downloads github repositories containing the jobs to execute and the Docker
images used to run them, via the OpenSAFELY proxies (see below).

### collector

This service lives in ~opensafely/collector.

It collects and emits host metrics.

### Airlock app and daily jobs

These services live in ~opensafely/airlock.

The Airlock service runs the Airlock web app, which listens on port 80, and is
accessible only from Level 4.

The Airlock runjobs service runs the [daily Airlock jobs](https://github.com/opensafely-core/airlock/tree/36aaa7c658e84ea50d4e8acbf07d6095d15e9f63/airlock/jobs).


## Network Requirements

An OpenSAFELY backend requires egress to 157.245.31.108 (dokku4) on port 443.

If routing via a HTTPS proxy, then the following domains are required (all accessible via that IP):

    docker-proxy.opensafely.org
    github-proxy.opensafely.org
    release.opensafely.org
    controller.opensafely.org
    collector.opensafely.org
    backends.opensafely.org
    archive-ubuntu.opensafely.org
    security-ubuntu.opensafely.org

Note: the docker and github proxy domains proxy HTTPS requests through to `ghcr.io` and
`github.com` respectively. They restrict access to the OpenSAFELY and
opensafely-core Github organisations only, and are read only.
