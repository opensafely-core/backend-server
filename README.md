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
