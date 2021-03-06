# OpenSAFELY backend server management

OpenSAFELY backends are deployed on servers inside our partners' secure
environments. These servers are provisioned and managed by the provider,
with limited network access. They are designed to run the
[job-runner](https://github.com/opensafely-core/job-runner) process,
which polls jobs.opensafely.org for work, and then runs the requested
actions securely inside docker containers. It generally also handles the
process for redaction, review and publication of outputs.

Due to being deployed in different partner's environments, and us not
always having full administrative control of that environment, each
backend is different in some way. We do try to minimise these
differences, but they are unavoidable.

## Usage

Check out the version of this repo you wish to use (typically main), and then run:

    sudo ./YOUR_BACKEND/manage.sh

This will ensure the right packages, users, groups is configured, and set up
jobrunner and other services as needed.


## Development

Directory layout:

* ./scripts
  * various bash scripts to perform specific actions, designed to be idempotent
* ./etc
  * system configuration files/templates
* ./tpp-backend
  * scripts and config for tpp backend
* ./emis-backend
  * scripts for config for emis backend
* ./emis-access
  * scripts for managing emis-access VM
* ./jobrunner
  * scripts and config templates for jobrunner
* ./osrelease
  * scripts and config templates for osrelease
* ./keys/$USER
  * public keys to add to ssh for $USER
* ./developers
  * developers gh account list. To be replaced by authenticated API call to
    job-server later, perhaps.
* ./tests
  * test scripts, run in docker container by makefile
* ./run-in-docker.sh
  * runner for above tests. Uses docker to emulate a VM to run scripts on.
* ./run-in-vm.sh
  * helper for running the scripts inside an actual vm for manual debugging/testing

## Testing

To run tests:

    make test

To run specific tests (tab completes)

    make tests/$TEST

If you specify DEBUG=1, then you will be dropped into a shell inside the docker
container after the tests has run.

To to create and run a specific backend, you can do:

    make tpp-backend

or

    make emis-backend

These will setup a VM with that backend both drop you into a shell. The VM will
be destroyed when you exit the shell.


## Base assumptions

 * Ubuntu server (20.04 baseline)
 * Internet access to {jobs,docker-proxy}.opensafely.org
 * Internet access to an official ubuntu archive
 * Internet access github.com
 * SSH access for developers to the backend host
 * sudo access on the host in some form
 * Just bash and git needed on the host to bootstrap backend.


## Common goals for all backends

 * docker installed and configured appropriately
 * maintain developers' linux accounts and ssh keys
 * maintain level2/3/4 groups and membership of those groups
 * shared account for running each services, which developers can su to.
 * directories for high and medium privacy outputs, with access
 * controlled by groups


## Users and permissions

Users are created with their github account names, and their github public keys
added to `authorized_keys`. Additional non-Github registered public keys can be
added to keys/$USER in this repo if needed.

There are 3 groups to manage permissions:

developers: sudo access. Level 2 in opensafely terms.
researchers: read access to high privacy files. Level 3.
reviewers: read/write access to medium privacy files. level 4.

Note: Long-term, reviewers will not have local accounts, but instead review via a webapp.


## Specific Backend Details

 - [TPP](tpp-backend/README.md)
 - [EMIS](emis-backend/README.md)
