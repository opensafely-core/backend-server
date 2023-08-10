# Samba share of level 4 from VM.

The initial deployment of opensafely on TPP hosts medium privacy files at
`/e/FILEFORL4`. TPP maintain a sync script that copies these files to the level
4 VM regularly, where users can view them and release them.

When moving to the Ubuntu VM on TPP, we need to preserve this syncing behaviour
for a while, as while users can view the files via job-server/release-hatch,
they still need to release them with `osrelease`.


To do this, we configure the VM to expose a readonly samba share of
`/srv/medium_privacy/workspaces`, which TPP can use with their sync script.

This is expected to be a temporary solution, and will go away once releases can
be done via the releases UI rather than `osrelease`

## Set up instructions

`sudo apt install samba`

Add this snippet to the end of `/etc/samba/samba.conf`:

```
[level 4]
  comment = Level 4 outputs
  path = /srv/medium_privacy/workspaces
  read only = yes
  browsable = yes
  force group = reviewers
  hide files = cache
```

And restart samba:

`sudo systemctl restart smbd nmbd`

