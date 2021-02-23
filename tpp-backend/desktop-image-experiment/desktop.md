## Creating a Hyper-V image

Tried to do script this, failed, so here is the manual procedure to
create, configure and possibly export a Hyper-V image for an OpenSAFELY
backend.

## Create Initial VM

Use 'Quick Create' to launch 20.04 image from the Hyper-V Manager. This
will download a customised 20.04 *desktop* image, which plays nice as a
guest with Hyper-V. Note attempts to use a default server image have met
with crushing failure and despair.

This default image does not come with ssh installed. You must log on
graphically and set that up. Go through the initial sign in stuff,
create an account with same name as your github user, and whatever
password you want (it will be reset later). Canonical will try get you
to opt in to stuff, but refuse everything

## Enable SSH access

You will need an SSH key on your windows host, if you haven't already.

    ssh-keygen -t ed25519

Run the following:

    apt update && apt install ssh-server git ssh-import-id

If your windows key is registered with Github, then:

    ssh-import-id gh:$USER

Other wise, manually copy your local public key into
`~/.ssh/authorized_keys`.

Note the IP address:

    ip address show eth0

Check you can ssh in from the windows host (e.g via git-bash):

    ssh USER@IPADDRESS

Now we can disconnect from GUI and continue via SSH.

## Configure the VM

Assuming you are ssh'd in:

    git clone git@github.com/opensafely-core/backend-server
    cd backend-server
    # remove unwanted desktop bloat.
    ./tpp-backend/clean-desktop.sh
    ./tpp-backend/manage.sh


Check everything looks correct.

When satisfied, run:

     ./scripts/clean-image.sh

This will clean the image of secrets:

  - reset all users passwords
  - remove system sshd keys, and configure cloud-init to generate new
    ones next boot
