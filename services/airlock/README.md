# airlock

This directory contains the configuration for the airlock service. It
runs as a docker container via `docker compose`, and is automatically updated to
the :latest tag.

The container is always named `airlock`, and can be managed using
normal docker tools or via `docker compose`.

# Configuration

airlock shares the same configuration as jobrunner, which currently lives
in `/home/opensafely/config/*.env`. In particular, it uses `AIRLOCK_API_TOKEN` to
sign and validate requests. This currently duplicates `JOB_SERVER_TOKEN`.

# TLS certificates

TLS certificates are configured and renewed externally via the
backends.opensafely.org configuration on dokku4. The are stored in the backend
at at `~opensafely/airlock/certs/airlock.{crt,key}`, and are used by the docker
container to enable TLS in gunicorn.

When first setting up airlock for real on a new host, you will need to copy the
private key from dokku4 to the new host - it is reused, so will not change.

After that, the regular `just autodeploy` mechanism will automatically pull
down new public certificates as they are renewed as part of a deployment. See
`just update-certs` command for details.

When the envvar TEST=true, then self-signed certificates will be generated, and
the automatic updates will be skipped. This is used in the test suite.

# Useful commands

All these commands assume you are runing from `~opensafely/airlock` directory.

 - *restart*: docker compose restart
 - *logs*: docker compose logs
 - *root shell*: docker compose exec -u 0 airlock bash
