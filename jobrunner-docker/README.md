# jobrunner-docker

This directory contains the configuration for the
[job-runner](https://github.com/opensafely-core/job-runner/) service. It
runs as a docker container via docker-compose, and is automatically updated to
the :latest tag.

The container is always named `job-runner`, and can be managed using
normal docker tools or via docker-compose.

# Configuration

job-runner installs configuration which release-hatch also shares, this lives in
`/srv/jobrunner/environ/*.env`.

# Useful commands

All these commands assume you are runing from `~jobrunner/job-runner` directory.

 - *restart*: docker-compose restart 
 - *logs*: docker-compose logs
 - *update*: ./deploy.sh
 - *root shell*: docker-compose exec -u 0 job-runner bash
