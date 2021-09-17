# release-hatch

This directory contains the configuration for the release-hatch service. It
runs as a docker container via docker-compose, and is automatically updated to
the :latest tag.

The container is always named `release-hatch`, and can be managed using
normal docker tools or via docker-compose.

# Configuration

release-hatch shares the same configuration as jobrunner, which lives in
`/srv/jobrunner/environ/*.env`.

# Useful commands

All these commands assume you are runing from `~jobrunner/release-hatch` directory.

 - *restart*: docker-compose restart 
 - *logs*: docker-compose logs
 - *update*: ./deploy.sh
 - *root shell*: docker-compose exec -u 0 release-hatch bash
