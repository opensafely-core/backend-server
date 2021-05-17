# OpenSAFELY Backend System Requirements

## Base System

The OpenSAFELY backend is designed and tested to run on an Ubuntu 20.04 LTS VM.

This should have access to an appropriate Ubuntu archive mirror, and be
configured to apply security updates automatically.


## Dependencies

The required packages are `python3` (which is python 3.8 in 20.04) and
`docker.io` (the Ubuntu packaged version of docker).

The explicit list can be found in [core-packages.txt](core-packages.txt).


## Services

The is currently a single service, `job-runner`, which is installed in /srv/jobrunner.
A `jobrunner` user is created to run it, and appropriate systemd unit file is installed.

This service does not listen on any port, but regularly polls out to the
OpenSAFELY platform, for new jobs or publishing job status or results.


## Network Requirements

An OpenSAFELY backend requires egress to 157.245.31.108 on port 443.

If routing via a HTTPS proxy, then the following domains are required (all accessible via that IP):

    jobs.opensafely.org
    docker-proxy.opensafely.org
    github-proxy.opensafely.org


Note: the 2 proxy domains proxy HTTPS requests through to `ghcr.io` and
`github.com` respectively. They restrict access to the OpenSAFELY and
opensafely-core Github organisations only, and are read only.

