# Operations

## Updating the infrastructure

To update to the latest version of the backend-server, make sure you have local
checkout of [opensafely-core/backend-server](https://github.com/opensafely-core/backend-server) at
the version you want to apply, then run:

    sudo just manage

This will apply all current backend server configuration, including users, groups,
and jobrunner configuration.


## opensafely user

**IMPORTANT**: All operations begin by switching from your user to
the opensafely user with:

    sudo su - opensafely


## jobrunner service
This will set up your shell with the correct environment variables.

The jobrunner is installed in `/home/opensafely/jobrunner`

    /home/opensafely/jobrunner/code     # the checkout of jobrunner currently running
    /home/opensafely/jobrunner/lib      # dependencies for jobrunner, added via PYTHONPATH
    /home/opensafely/config  # environment configuration
    /home/opensafely/secret   # any secret files (e.g. x509 client certificates for emis)


### Starting/stopping the service

Run the appropriate command:

    just jobrunner/start
    just jobrunner/stop
    just jobrunner/restart

All of these are allowed to be run by the opensafely user via sudo without
a password, or can be run as your regular user too.

### Viewing job-runner logs

#### Using just

You can view logs via:

    just jobrunner/logs <lines>

This uses a pager and defaults to 1000 lines, so may not show relevant logs if you're looking for more distant events. Alternative values to try include "2000" or "all".

To look for all logs for a specific job id:

    just jobrunner/logs-id <job_id>

### Configuring the job-runner

All env files are in /home/opensafely/config/\*.env

    01_defaults.env   # job runner default production values. DO NOT EDIT
    02_secrets.env    # secrets for this backend (e.g. github tokens)
    03_backend.env    # backend specific configuration. DO NOT EDIT
    04_local.env      # local overrides - use this to temporarily override config

If you wish to change the config in `01_defaults.env` or `03_backend.env`, you
need to merge a change to the `services/jobrunner/defaults.env` or
`BACKEND/backend.env`, and update the infrastructure code as above.


### Deploy job-runner

1. If there are new config fields, update by adding to appropriate files in `/home/opensafely/config`.

2. Update and restart jobrunner via:


```bash
just jobrunner/deploy
```

Notes: the script to actually do all this is in `~opensafely/bin/update-jobrunner.sh`. It basically does some checks, and then:

 a) update dependencies
 b) pull code
 c) run migrations
 d) restart service

### Update docker image

Run:

    update-docker-image.sh image[:tag]

Note that the script provides the repository name, so you must provide
only the last component of the image name. For example to update the R
image, image name to provide is `r`, not `ghcr.io/opensafely-core/r`.

## Debugging jobs

### Show currently running jobs

See the list of currently running jobs, with job identifier, job name and associated workspace in job-server:

```
just jobrunner/jobs-ls
```

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


### Viewing resource usage of jobs

View the CPU and memory usage of jobs using:

```
just jobrunner/jobs-stats
```

To see overall system CPU and memory usage, use

```
free -m
```

to show available memory.

To show system load, memory and CPU usage, run:

```
top
```

### stracing a running job

Start a privileged container which can see other containers processes:

    docker run --rm -it --privileged --pid=host ghcr.io/opensafely-core/tools

Find the pid of the relevant process inside the job in question:

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

    just jobrunner/job-retry <job_id>

The `job_id` actually only has to be a sub-string of the job ID (full
ones are a bit awkward to type) and you will be able to select the
correct job if there are multiple matches.


### Killing a job 

To kill a running job (or prevent it starting if it hasn't yet) use the
`kill_job` command:

    python3 -m jobrunner.cli.kill_job --cleanup <job_id> [... <job_id>]

The `job_id` actually only has to be a sub-string of the job ID (full
ones are a bit awkward to type) and you will be able to select the
correct job if there are multiple matches.

Multiple job IDs can be supplied to kill multiple jobs simultaneously.

The `--cleanup` flag deletes any associated containers and volumes,
which is generally what you want.

If you want to kill a job but leave the container and volume in place
for debugging then omit this flag.

The command is idempotent so you can always run it again later with the
`--cleanup` flag.

### Debugging slow queries

The only way to gauge whether a DB job is stuck is to look at the docker logs
for the running job. You can look at the log timestamps to see when it issued
the current query.


There is a helpful script to view this at a glance: `current-queries.sh`. It
will show the last SQL timestamp of all running *cohortextractor* jobs, giving
you an idea of how long the job has been waiting on the db for.

`current-queries.sh v` will *also* print the actual SQL, which can be very large.

#### Assessing query progress in mssql

To estimate the rowcount of a table which is being `INSERT`ed to,
the following queries may be run within SSMS or other SQL command
interpreter connected to the TPP SQL Server.

For session-scoped, `#`-prefixed temporary tables:

    SELECT t.name, p.rows 
    FROM tempdb.sys.tables t
    JOIN tempdb.sys.partitions p
      ON t.object_id = p.object_id
    WHERE t.name like '<temp table name>%'

_N.B. this will return an estimate of the row count as we lack
the permissions to obtain an accurate row count for these tables_

For tables within the `OpenCORONATempTables` database:

    SELECT COUNT(*) FROM <name of table> (NOLOCK).


### Removing a Level 4 file

There are times when these medium privacy outputs may need to be deleted. For
example, the researcher or output checkers may realise they should have been
marked as high privacy, or the researcher may no longer need the output and
want to preserve disk space.

All outputs are put into the `/srv/high_privacy/workspaces/` directory for
a workspace on the VM.

Outputs that have been marked as having a medium privacy level are then copied
into the matching `/srv/medium_privacy/workspaces/` directory.

To remove a level 4 file, you can just delete the file from the correct
`/srv/medium_privacy/workspaces/$WORKSPACE` directory.


#### Removing a Level 4 file from TPP

Medium privacy outputs are copied from L3 to L4 every five minutes by a sync
script controlled by TPP. *Note: this sync script is unidirectional, so any
changes to L4 are not reflected back to the source files in the VM.*

Once you have removed the file from `/srv/medium_privacy` as per above, you then need to:

1. Login to L4 (after deleting the file from L3)
2. Browse to `D:\Level4Files\workspaces\$WORKSPACE`
3. Permanently delete the file (using SHIFT+DEL or by emptying the recycle bin after deleting normally).


## Start up and Shutdown

### Preparing for reboot

Sometimes we need to restart Docker, or reboot the VM in which we're
running, or reboot the entire host machine. When the happens, it's nicer
if we can automatically restart any running jobs rather than have them
fail and force the user to manually restart them.

To do this, first stop the [job-runner service](#startingstopping-the-service):

```sh
just jobrunner/stop
```

After the service is stopped you can run the `prepare_for_reboot` command:

```sh
just jobrunner/prepare-for-reboot
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
sleep $((4*3600)); just jobrunner/stop && just jobrunner/prepare-for-reboot
```

### After a restart

#### Level 3 file sync

This command ensures files manually generated on the Windows host are copied to the Ubuntu VM (both Level 3). It's only used by a small number of researchers, as normally researchers would access their outputs via Level 4.

From a Tmux session run:

```sh
while true; do rsync -auP /e/FILESFORL4/workspaces/ /srv/medium_privacy/workspaces/ ; sleep 120; done
```

*Tip: Search the bash history to find the command rather than typing it out*

### Pausing new jobs

When we know ahead of time that there will be a period when the system is going to be unavailable, such as planned maintenance, we may decide to stop accepting new jobs. This may be because they're unlikely to complete in time or to give current jobs a better chance of finishing.


Stop accepting new jobs:

```sh
just jobrunner/pause
```

Start accepting new jobs again:

```sh
just jobrunner/unpause
```

Setting and unsetting flags takes effect immediately, so it's not necessary to restart jobrunner.
