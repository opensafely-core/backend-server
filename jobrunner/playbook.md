# Operations

## Updating the infrastructure

To update to the latest version of the backend-server, make sure you have local
checkout of `opensafely-core/backend-server` at the version you want to apply,
then run:

    sudo ./BACKEND/manage.sh

Where BACKEND is the backend you are currently on. This will apply all current
backend server configuration, including users, groups, and jobrunner
configuration.


## jobrunner

**IMPORTANT**: All job-runner operations begin by switching from your user to
the jobrunner user with:

    sudo su - jobrunner

This will set up your shell with the correct environment variables.

The jobrunner intalled in `/srv/jobrunner`

    /srv/jobrunner/code     # the checkout of jobrunner currently running
    /srv/jobrunner/lib      # dependencies for jobrunner, added via PYTHONPATH
    /srv/jobrunner/environ  # environment configuration
    /srv/jobrunner/secret   # any secret files (e.g. x509 client certificates for emis)


### Starting/stopping the service

Run the appropriate command:

    sudo systemctl restart jobrunner
    sudo systemctl stop jobrunner
    sudo systemctl start jobrunner

All of these are allowed to be run by the jobrunner user via sudo without
a password, or can be run as your regular user too.

### Viewing job-runner logs

You can view logs via journtalctl:

    journalctl -xe -u jobrunner

### Configuring the job-runner

All env files are in /srv/jobrunner/environ/\*.env

    01_defaults.env   # job runner default production values. DO NOT EDIT
    02_secrets.env    # secrets for this backend (e.g. github tokens)
    03_backend.env    # backend specific configuration. DO NOT EDIT
    04_local.env      # local overrides - use this to temporarily override config

If you wish to change the config in `01_defaults.env` or `03_backend.env`, you
need to merge a change to the `jobrunner/defaults.env` or
`BACKEND/backend.env`, and update the infrastructure code as above.

### Update job-runner

In `/srv/jobrunner/code` run:

    git pull

Then restart the service



### Update docker image

Run:

    update-docker-image.sh image[:tag]

Note that the script provides the repository name, so you must provide
only the last component of the image name. For example to update the R
image, image name to provide is `r`, not `ghcr.io/opensafely-core/r`.

## Debugging jobs

### View specific job logs

    watch-job-logs.sh

This will let you choose a job's output to tail.

Supply a string argument to filter to just job names matching that
string. If there is only one match it will automatically select that
job.


### Mount the volume of a running job

    mount-job-volume.sh

Starts a container with the volume associated with a given job mounted
at `/workspace`.

Supply a string argument to filter to just job names matching that
string. If there is only one match it will automatically select that
job.

Note that the container will be a privileged "tools" container suitable
for stracing (see below).


### stracing a running job

Start a privileged container which can see other containers processes:

    docker run --rm -it --privileged --pid=host ghcr.io/opensafely-core/tools

Find the pid of the relevent process inside the job in question:

    ps faux | less

Strace it:

    strace -fyp <pid>


### Retrying a job which failed with "Internal error"

When a job fails with the message "Internal error" this means that
something unexpected happened and an exception other than JobError was
raised. This can be a bug in our code, or something unexpected in the
environment. (Windows has sometimes given us an "I/O Error" on
perfectly normal file operations.)

When this happens the job's container and volume are not
automatically cleaned up and so it's possible to retry the job without
having to start from scratch. You can run this with:

    python3 -m jobrunner.retry_job <job_id>

The `job_id` actually only has to be a sub-string of the job ID (full
ones are a bit awkward to type) and you will be able to select the
correct job if there are multiple matches.


### Killing a job

To kill a running job (or prevent it starting if it hasn't yet) use the
`kill_job` command:

    python3 -m jobrunner.kill_job --cleanup <job_id> [... <job_id>]

The `job_id` actually only has to be a sub-string of the job ID (full
ones are a bit awkward to type) and you wil be able to select the
correct job if there are multiple matches.

Multiple job IDs can be supplied to kill multiple jobs simultaneously.

The `--cleanup` flag deletes any associated containers and volumes,
which is generally what you want.

If you want to kill a job but leave the container and volume in place
for debugging then omit this flag.

The command is idempotent so you can always run it again later with the
`--cleanup` flag.
