# release-hatch

This directory contains the configuration for the release-hatch service. It
runs as a docker container via docker-compose, and is automatically updated to
the :latest tag.

The container is always named `release-hatch`, and can be managed using
normal docker tools or via docker-compose.

# Configuration

release-hatch shares the same configuration as jobrunner, which currently lives
in `/home/opensafely/config/*.env`. In particular, it uses `JOB_SERVER_TOKEN` to
sign and validate requests, and it uses `RELEASE_HOST` to know what domain it
should be serving files from.

The only additional configuration is the TLS cert/key files. These live at
`~opensafely/release-hatch/certs/release-hatch.{crt,key}`, and are used by the
docker container to configure TLS. 

The default install will generate self-signed certifcates, but these can replaced.

# Useful commands

All these commands assume you are runing from `~opensafely/release-hatch` directory.

 - *restart*: just restart
 - *logs*: just logs
 - *update*: just deploy
 - *root shell*: docker-compose exec -u 0 release-hatch bash
