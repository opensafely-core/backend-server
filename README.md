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

## Usage

Check out the version of this repo you wish to use (typically main), and then run:

    sudo ./scripts/bootstrap.sh YOUR_BACKEND
    # e.g. sudo ./scripts/bootstrap.sh tpp
    sudo just manage

This will ensure the right packages, users, groups is configured, and set up
jobrunner and other services as needed.

Note: the checkout is ephemeral so it doesn't matter where you check the repo out
(your home dir is fine) or whether there are other checkouts already on the server.

## Base assumptions

 * Ubuntu server (20.04 baseline)
 * Internet access to {jobs,docker-proxy,github-proxy}.opensafely.org
 * Internet access to an official ubuntu archive
 * SSH access for developers to the backend host
 * sudo access on the host in some form
 * Just bash and git needed on the host to bootstrap backend.

## Components

### Workspace state

Currently in `/srv/high_privacy` and `/srv/medium_privacy`. Files owned by
`jobrunner` user. Medium privacy files can be read by `reviewers` group.

### job-runner
 
Repo: https://github.com/opensafely-core/job-runner

Manages the jobs and their state. Currently deployed in `/home/jobrunner` as a git
checkout and managed by a systemd unit.  Plan is to move this to docker
soonish.

### osrelease

Repo: https://github.com/opensafely-core/output-publisher

Command line tool to release files. Currently deployed via `sudo pip install`,
which is problematic, so will be switching something else soonish.

### release-hatch

Repo: https://github.com/opensafely-core/release-hatch

New tool to manage the review and release process. Will hopefully replace osrelease soonish.
Deployed as a docker service via `docker-compose`.


## Common goals for all backends

 * docker installed and configured appropriately
 * maintain developers' linux accounts and ssh keys
 * maintain level2/3/4 groups and membership of those groups
 * shared account for running each services, which developers can su to.
 * directories for high and medium privacy outputs, with access
 * access controlled by groups

## Users and permissions

Users are created with their github account names, and their github public keys
added to `authorized_keys`. Additional non-Github registered public keys can be
added to keys/$USER in this repo if needed.

There are 3 groups to manage permissions:

* developers: sudo access. Level 2 in opensafely terms.
* researchers: read access to high privacy files. Level 3.
* reviewers: read/write access to medium privacy files. level 4.

Note: Long-term, reviewers will not have local accounts, but instead review via a webapp.


## Specific Backend Details

 - [TPP](backends/tpp/README.md)
 - [EMIS](backends/emis/README.md)
