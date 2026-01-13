# Operations

## Updating the infrastructure

To update to the latest version of the backend-server, navigate to `/srv/backend-server`, 
make sure you have local checkout of
[opensafely-core/backend-server](https://github.com/opensafely-core/backend-server) at
the version you want to apply, then run:

    sudo just manage

This will apply all current backend server configuration, including users, groups,
and jobrunner configuration.

### Updating changes to services

To update changes to a single service (e.g. jobrunner or airlock) without updating
all system packages etc, run w.g:

    sudo just install-airlock

## opensafely user

**IMPORTANT**: All operations begin by switching from your user to
the opensafely user with:

    sudo su - opensafely

This will set up your shell with the correct environment variables.


/home/opensafely/config  # environment configuration
/home/opensafely/secret   # any secret files (e.g. x509 client certificates for emis)
/home/opensafely/jobrunner  # jobrunner service workdir and configuration
/home/opensafely/airlock    # airlock service workdir and configuration
/home/opensafely/collector  # otel collector service

## jobrunner service

The jobrunner is installed in `/home/opensafely/jobrunner`.

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

    just jobrunner/logs [args...]

This uses `docker compose logs` under the hood, and args will be passed to that
command. e.g. -n 1000 will show you 1000 lines, -f follows, etc.

To look for all logs for a specific job id:

    just jobrunner/logs-id <job_id>

### Configuration management

All env files are in /home/opensafely/config/\*.env

    01_defaults.env   # job runner default production values. DO NOT EDIT
    02_secrets.env    # secrets for this backend (e.g. github tokens)
    03_backend.env    # backend specific configuration. DO NOT EDIT
    04_local.env      # local overrides - use this to temporarily override config

If you wish to change the config in `01_defaults.env` or `03_backend.env`, you
need to merge a change to the `config/defaults.env` or
`BACKEND/backend.env`, and update the infrastructure code as above.

#### Database Network Configuration

The config values `DATABASE_ACCESS_NETWORK` and `DATABASE_IP_LIST` need some
care when changing, or else running db jobs may fail due to the changes.

To apply changes to these values:

As opensafely user:
1) manually enable DB maintenance mode to kill running db jobs: `just jobrunner/db-maintenance-on`
2) stop jobrunner: `just jobrunner/stop`
3) change the values in the config files

As root:
4) from /srv/backend-server, run `just install-docker-network` to recreate the docker network

As opensafely user:
5) start job-runner: `just jobrunner/start`
6) disable db maintenance mode: just jobrunner/db-maintenance-off


### Deploy job-runner

1. If there are new config fields, update by adding to appropriate files in `/home/opensafely/config`.

2. Update and restart jobrunner via:


```bash
just jobrunner/deploy
```

### Update docker image

> [!NOTE]
> [Action images](#action-images) do not usually need to be manually updated.

To update a docker image, run:

    just jobrunner/update-docker-image image[:tag]

Note that the script provides the repository name, so you must provide
only the last component of the image name. For example to update the
`tpp-database-utils` image, the image name to provide is `tpp-database-utils`,
not `ghcr.io/opensafely-core/tpp-database-utils`.

#### Updating tpp-database-utils

```bash
just jobrunner/update-docker-image tpp-database-utils:latest
```

#### Action images

Action images (ehrql, r, python etc) are pulled automatically when a job that
uses them runs.

If necessary, they can be updated manually. For example, to update the ehrQL Docker image, run:

```bash
just jobrunner/update-docker-image ehrql:v1
```

## Debugging jobs

### Show currently running jobs

See the list of currently running jobs, with job identifier, job name and associated workspace in job-server:

```
lsjobs
```

or
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


### Killing a job task

The RAP Agent runs tasks with job information that it receives from the RAP Controller.
If something goes wrong with the execution of a task, the Agent keep retrying it.

If necessary a task can be killed - this will kill and delete and running docker
containers and delete any associated volumes. Note that if the Agent is running and
receiving task updates from the Controller, it will attempt to retry the task again.

To kill a running task use the
`kill_task` command:

    just jobrunner/kill_task <job_id> [... <job_id>]

The `job_id` actually only has to be a sub-string of the job ID (full
ones are a bit awkward to type) and you will be able to select the
correct job if there are multiple matches.

Multiple job IDs can be supplied to kill multiple job tasks simultaneously.


### Debugging slow queries

The only way to gauge whether a DB job is stuck is to look at the docker logs
for the running job. You can look at the log timestamps to see when it issued
the current query.

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

### Manual DB Maintenance mode

Sometimes, we need to just stop db jobs from running.

This can be done with the following commands, which will kill running db jobs
and re-queue them to run when db-maintenance mode is switched off.

```sh
just jobrunner/db-maintenance-on
```
and
```sh
just jobrunner/db-maintenance-off
```

### Planned maintenance

Sometimes we are informed that a reboot will take place out of hours. In this case, in order to ensure a graceful shutdown and to avoid someone having to work late, the [preparing for reboot](#preparing-for-reboot) section can be run as a single command with a sleep statement.

For example, this will start shutting things down in four hours:

```sh
sleep $((4*3600)); just jobrunner/stop && just jobrunner/prepare-for-reboot
```

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
