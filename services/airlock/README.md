# airlock

This directory contains the configuration for the airlock service. It
runs as a docker container via `docker compose`, and is automatically updated to
the :latest tag.

The container is always named `airlock`, and can be managed using
normal docker tools or via `docker compose`.

# Configuration

airlock shares the same configuration as jobrunner, which currently lives
in `/home/opensafely/config/*.env`. It requires the following environment variables:

* `DJANGO_ALLOWED_HOSTS` in backend.env
* `DJANGO_SECRET_KEY` in secrets.env
* `AIRLOCK_API_TOKEN` in secrets.env (this duplicates `JOB_SERVER_TOKEN`)

The only additional configuration is the TLS cert/key files. These live at
`~opensafely/airlock/certs/airlock.{crt,key}`, and are used by the
docker container to configure TLS. 

The default install will generate self-signed certifcates, but these can replaced.

# Useful commands

All these commands assume you are runing from `~opensafely/airlock` directory.

 - *restart*: docker-compose restart
 - *logs*: docker-compose logs
 - *root shell*: docker-compose exec -u 0 airlock bash
