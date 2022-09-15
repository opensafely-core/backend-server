# Operations

## Updating the infrastructure

To update to the latest version of the backend-server, make sure you have local
checkout of `opensafely-core/backend-server` at the version you want to apply,
then run:

    sudo ./BACKEND/manage.sh

Where BACKEND is the backend you are currently on. This will apply all current
backend server configuration, including users, groups, and jobrunner
configuration.


## jobrunner service

### jobrunner user

**IMPORTANT**: All operations begin by switching from your user to
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

Note: `-e` engages the pager, so you can scroll up.  It is implicitly limited to 1000, so may not show relevant logs if you're looking for more distant events.  Use e.g. `-n2000` to increase the limit, or `-nall` to disable it.

To look for all logs for a specific job id:

    journalctl -u jobrunner | grep <job id>

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

### View the logs of completed jobs

Every completed job (whether failed or succeeded) has a log directory at:

    /srv/high_privacy/logs/<YYYY-MM>/os-job-<job_id>

This contains two files:

 * `logs.txt`:
   *  this contains all stdout/stderr output from the job;
   *  it's identical to the file found in `metadata/<action_name>.log`
      but it's available for all historical jobs, not just the most
      recently run.
 * `metadata.json`:
   * this is a big JSON blob containing everything we know about the job
     and the job request which initiated it;
   * it also contains all the Docker metadata about the container used
     to run it.

### View the logs of running jobs

    watch-job-logs.sh

This will let you choose a job's output to tail from all currently
running jobs.

Supply a string argument to filter to just job IDs matching that
string. If there is only one match it will automatically select that
job.


### Mount the volume of a running job

    mount-job-volume.sh

Starts a container with the volume associated with a given job mounted
at `/workspace`.

Supply a string argument to filter to just job IDs matching that
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

    python3 -m jobrunner.cli.retry_job <job_id>

The `job_id` actually only has to be a sub-string of the job ID (full
ones are a bit awkward to type) and you will be able to select the
correct job if there are multiple matches.


### Killing a job

To kill a running job (or prevent it starting if it hasn't yet) use the
`kill_job` command:

    python3 -m jobrunner.cli.kill_job --cleanup <job_id> [... <job_id>]

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

## Start up and Shutdown

### Preparing for reboot

Sometimes we need to restart Docker, or reboot the VM in which we're
running, or reboot the entire host machine. When the happens, it's nicer
if we can automatically restart any running jobs rather than have them
fail and force the user to manually restart them.

To do this, first stop the [job-runner service](#startingstopping-the-service):

```sh
systemctl stop jobrunner
```

After the service is stopped you can run the `prepare_for_reboot` command:

```sh
python3 -m jobrunner.cli.prepare_for_reboot
```

This is quite a destructive command as it will destroy the containers
and volumes for any running jobs. It will also reset any currently
running jobs to the pending state.

The next time job-runner restarts (which should be after the reboot) it
will pick up these jobs again as if it had not run them before and the
user should not have to do anything.

### Planned maintenance

Sometimes we are informed that a reboot will take place out of hours. In this case, in order to ensure a graceful shutdown and to avoid someone having to work late, the [preparing for reboot](#preparing-for-reboot) section can be run as a single command with a sleep statement.

For example, this will start shutting things down in four hours:

```sh
sleep $((4*3600)); systemctl stop job-runner && python -m jobrunner.cli.prepare_for_reboot
```

### After a restart

#### Level 3 file sync

This command ensures files manually generated on the Windows host are copied to the Ubuntu VM (both Level 3). It's only used by a small number of researchers, as normally researchers would access their outputs via Level 4.

From a Tmux session run:

```sh
while true; do rsync -auP /e/FILESFORL4/workspaces/ /srv/medium_privacy/workspaces/ ; sleep 120; done
```

*Tip: Search the bash history to find the command rather than typing it out*