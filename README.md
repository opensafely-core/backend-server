# OpenSAFELY backend server management

OpenSAFELY backends are deployed on servers inside our partners' secure
environments. These servers are provisioned and managed by the provider,
with limited network access. They are designed to run the
[job-runner](https://github.com/opensafely-core/job-runner) process,
which polls jobs.opensafely.org for work, and then runs the requested
actions securely inside docker containers. It also handles the process for
redaction, review and publication of outputs.

Due to being deployed in different partner's environments, and us not
always having full administrative control of that environment, each
backend is different in some way. We do try to minimise these
differences, but they are unavoidable.

## Initial Setup

First time on a new backend machine, you need to do an initial checkout and bootstrap.

```
sudo mkdir -m 755 -p /srv
sudo git clone https://github-proxy.opensafely.org/opensafely-core/backend-server /srv/backend-server
cd /srv/backend-server
sudo ./scripts/bootstrap.sh $BACKEND
```

After running bootstrap you may wish to restart your shell in order to enable 
autocompletion for `just`.

## Usage

You should work from the /srv/backend-server directory.  All commands should be
be run as root, invoked via just.

```
sudo just manage
```

This will ensure the right packages, users, groups are configured, and set up
jobrunner and other services as needed.

A plain `just` will list other commands available, with help


## Base assumptions

 * Ubuntu server (22.04 baseline)
 * Internet access to {jobs,docker-proxy,github-proxy}.opensafely.org
 * Internet access to an official ubuntu archive
 * SSH access for developers to the backend host
 * sudo access on the host in some form
 * Just bash and git needed on the host to bootstrap backend.

## Components

### Workspace state

Currently in `/srv/high_privacy` and `/srv/medium_privacy`. Files owned by
`opensafely` user. Medium privacy files can be read by `reviewers` group.

### job-runner
 
Repo: https://github.com/opensafely-core/job-runner

Manages the jobs and their state. Currently deployed in `/home/opensafely` as a git
checkout and managed by a systemd unit.  Plan is to move this to docker
soonish.

## Common goals for all backends

 * docker installed and configured appropriately
 * maintain developers' linux accounts and ssh keys
 * maintain level2/3/4 groups and membership of those groups
 * shared account for running each services, which developers can su to.
 * directories for high and medium privacy outputs, with access
 * access controlled by groups

## Users and permissions

Note: Access permission is defined in the 
[Developer Permissions Log](https://www.bennett.wiki/products/developer-permissions-log/); check the log before adding any new users.

Users are created with their github account names, and their github public keys
added to `authorized_keys`. Additional non-Github registered public keys can be
added to keys/$USER in this repo if needed.

There is one group to manage permissions:

* developers: sudo access. Level 2 in opensafely terms.


### Disabling users

Once a user has been removed from all user files (see above), they can be manually disabled with:

```
just disable-user USER
```

## Specific Backend Details

 - [TPP](backends/tpp/README.md)
