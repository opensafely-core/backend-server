# TPP Opensafely Backend

NOTE: THIS BACKEND IS NOT YET LIVE

## Accessing the backend

Note: you will need to have completed [Setting up ssh
access](#setting-up-ssh-access) below before you can log in via ssh.  

Once logged into the TPP Level 3 server via RDP, open git-bash and run:

TODO: update the hostname/IP once we have it.

```bash
ssh <github username>@opensafely-ttp
```


## Setting up ssh access

First, you will need to gain access to the TPP Level 3 server, with firewall
and RDP credentials.

Second, you will need to generate a local ssh key on that server.

 - *IMPORTANT*: this ssh key **MUST** have a good passphrase.
 - *IMPORTANT*: this ssh key **SHOULD NOT** be registered with your Github
   account

To generate a new key, open a git-bash terminal

```bash
ssh-keygen -t ed25519
```

Accept the default file location, and enter your passphrase.

You will need copy the contents of `~/.ssh/id_ed25519.pub`, and submit a PR to
https://github.com/opensafely-core/backend-server/ which adds the contents of
the above public key file to a file `./keys/<your github username>` in that
repository. Once this is merged, you should be able to log in to the backend VM.


## Overview

### Level 2/3 server

 - TPP provide a metal windows host server.
 - The backend runs in a Hyper-V VM on the host.
 - login to host is via authenticated firewall and RDP, accounts managed by
   TPP.
 - outgoing internet is restricted to https to our our cloudflare IPs,
   and https and ssh to github.com
 - TPP maintain a one-way push of medium privacy output files to the
   Level 4 server.
 - as TPP was early adopter, many users have RDP access to this machine.
 - goal is to reduce that to just the OpenSAFELY platform team.

### Level 4 Server

 - TPP provide a windows VM.
 - Login is via same firewall, but separate RDP account.
 - Redaction and publishing happens here.
 - Files pushed here from level 3.

### Implications

 - developers need a local SSH key on the Level 2/3 server to log in to
   the backend ubuntu server (RDP doesn't do agent forwarding!)
 - backend needs to write files to host filesystem for sync to level 4
   server, which requires an SMB mount in the backend.

### Hyper-V Image

TPP have no experience with operating Ubuntu machines. So, initially, we
provided them with a Hyper-V image, which they could pen test and
deploy.

To build this image, we used the tpp-backend/build-image.sh script, run
in git-bash on Windows.

Once the VM is deployed, we will maintain it directly, and do not
anticipate generating VM images regularly.

