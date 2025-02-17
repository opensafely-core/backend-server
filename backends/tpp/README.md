# TPP Opensafely Backend

## Accessing the backend

Note: you will need to have completed [Setting up ssh
access](#setting-up-ssh-access) below before you can log in via ssh.

Once logged into the TPP Level 3 server via RDP, open git-bash and run:


```bash
ssh <github username>@192.168.201.4
```


## Setting up ssh access

First, you will need to gain access to the TPP Level 3 server, with firewall
and RDP credentials.

Second, you will need to generate a local ssh key on that server.

 - *IMPORTANT*: this ssh key **MUST** have a good passphrase.
 - *IMPORTANT*: this ssh key **SHOULD NOT** be registered with your Github
   account, we cannot push to Github from TPP level 3 anyway.

To generate a new key, open a git-bash terminal

```bash
ssh-keygen -t ed25519
```

Accept the default file location, and enter your passphrase.

You will need copy the contents of `~/.ssh/id_ed25519.pub`, and submit a PR to
https://github.com/opensafely-core/backend-server/ which adds the contents of
the above public key file to a file `./keys/<your github username>` in that
repository.

Third, you need to ensure your github username is listed in the [developers file](https://github.com/opensafely-core/backend-server/blob/main/developers), as this is the master user account list.

Once this is merged, ask someone who already has access to update the
backend as
described
[here](https://github.com/opensafely-core/backend-server/blob/main/README.md#usage).

Then SSH into the VM as in the section above. You will be asked to set
a password; having done so you will be disconnected from the VM and
must SSH in again to actually access it.



## Overview

### Level 2/3 server

 - TPP provide a metal windows host server.
 - The backend runs in a Hyper-V VM on the host.
 - login to host is via authenticated firewall and RDP, accounts managed by
   TPP.
 - Outgoing internet is restricted to https to our cloudflare IPs
 - TPP maintain a one-way push of medium privacy output files to the
   Level 4 server.
 - As TPP was early adopter, many users have RDP access to this machine.
 - Goal is to reduce that to just the OpenSAFELY platform team. As such, we are
   only granting core OpenSAFELY team access to the VM.


### Level 4 Server

 - TPP provide a windows VM on the same host.
 - Login is via same firewall, but separate RDP account.
 - Redaction and publishing happens here.
 - Files pushed here from level 3.

### Implications

 - Developers need a local SSH key on the Level 2/3 server to log in to
   the backend ubuntu server (RDP doesn't do agent forwarding!)


### Hyper-V Image

TPP have no experience with operating Ubuntu machines. So, initially, we
provided them with a Hyper-V image, which they could pen test and
deploy.

To build this image, we used the backends/tpp/build-image.sh script, run
in git-bash on Windows.

Once the VM is deployed, we will maintain it directly, and do not
anticipate generating VM images regularly.

### Enabling Clock Sync

Hyper V clocks [will drift
slower](https://learn.microsoft.com/en-gb/archive/blogs/virtual_pc_guy/time-synchronization-in-hyper-v).
We don't have network access to an ntp server, but Hyper-V [provides a ptp
clock our linux guest can sync
with](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/time-sync).

Unfortunately, the 22.04 default of systemd-timesyncd does not support this. We
need to use chrony. However, installing, configuring, and testing that in our
LXD based test suite is hard/impossible. So instead, here we document the
manual steps involved in enabling clock sync.

Based on the microsft docs: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/time-sync

1. Double check that `/dev/ptp_hyperv` device exists. 
2. `sudo apt install chrony`. This should remove systemd-timesyncd, but can be a bit odd, may need to be re-run.
3. Add the following line to /etc/chrony/chrony.conf: ```refclock PHC /dev/ptp_hyperv poll 3 dpoll -2 offset 0 stratum 2```
4. Stop jobrunner, airlock temporarily, to avoid weirdness from adjusting the clock
5. `sudo systemctl restart chronyd && sudo systemctl restart chrony`
6. Restart jobrunner and airlock

You can check chrony is working correctly with `journalctl -u chrony`


