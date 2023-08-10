# NHSD Backend

This is the configuration for the NSHD Data Access Environment (DAE) hosted
backend.

This is different from other backends in that the system configuration, users
and ssh keys are managed by NHSD. The mangage.sh script for this backend
therefore just manages the job-runner setup.


We do not therefore use the default install script, and instead directly
install the packages core-packages.txt, and then just the job-runner itself.
