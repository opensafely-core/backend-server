#!/bin/bash
# This script is meant to be run in git-bash on Windows, and builds a hyper-v image
# You probably want an ssh-agent set up to run it.
# It's a bit awkward and manual in places, as windows is both.
#
# It has a much higher four-letter-words-per-line ratio
#
set -euo pipefail
name=opensafely-tpp
# user to ssh in with. Assumes your local ssh key will be added by the backend tooling.
sshuser=${1:-bloodearnest}
# path to export image to
path=${2:-D:\\}

# Create a new Gen 1 Ubuntu Hyper-v instance
# This is booted by multipass with default cloud-init config
# Ideally, we'd to this ourselves, and create a Gen 2 Hyper-V rather than Gen
# 1, but the benefits were not worth the cost.
multipass info $name || multipass launch 20.04 --name $name

# Udate and install hyper-v specific stuff kernel and services
multipass exec $name -- sudo apt-get update
multipass exec $name -- sudo apt-get upgrade -y
multipass exec $name -- sudo apt-get install -y linux-virtual-hwe-20.04 linux-tools-virtual-hwe-20.04 linux-cloud-tools-virtual-hwe-20.04
# Make sure it boots. Note: the reboot is important, as the installed hv-* services
# will not come up properly without it, which can mean our image does not boot
# down the line.
multipass restart $name

# Note: multipass mount is hella weird, so we just copy.
# Copy current directory to host
tarball=../current.tar
rm -f "$tarball"
tar cvf "$tarball" --exclude-vcs .
multipass transfer "$tarball" "$name://tmp/current.tar"
multipass exec $name -- sudo mkdir -p //tmp/config
multipass exec $name -- sudo tar xvf //tmp/current.tar -C //tmp/config

# save this for later
vmaddress="$(multipass exec $name -- hostname -I)"
echo "IP: $vmaddress"

# configure base TPP backend
multipass exec $name -- sudo env --chdir //tmp/config SHELLOPTS=xtrace ./tpp-backend/manage.sh

# clean up any unwanted stuff in the image
# The main thing this does is reset cloud-init to re-run on next boot, but with
# our custom cloud init config from ./cloud-init
multipass exec $name -- sudo env --chdir //tmp/config SHELLOPTS=xtrace ./tpp-backend/clean-image.sh


# We do not want the default ubuntu user. But as multipass relies on it, we can
# not delete it via multipass exec.  Instead we ssh in with a known good user (who's
# a different user in order to delete it
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$sshuser@$vmaddress" -- sudo pkill -u ubuntu
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$sshuser@$vmaddress" -- sudo userdel --remove ubuntu

# remove ssh host keys, cloud init will regenerate them on next boot
# Note: this must be the the last thing we do!
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$sshuser@$vmaddress" -- sudo rm //etc/ssh/ssh_host_*_key*

# ready to export
multipass stop $name

# remove the cloud-init iso that multipass uses
remove_cmd="Remove-VMHardDiskDrive -VMName $name -ControllerType IDE -ControllerNumber 0 -ControllerLocation 1"
# export the VM
export_cmd="Export-VM -Name $name $path -CaptureLiveState CaptureCrashConsistentState"
echo "Opening admin powershell..."

# powershell -c start -verb runas is the magic to invoke the UAC dialog
# Ideally, we'd just run these commands directly as an admin user, but I could
# not figure out the quoting to pass the commands through.
powershell -Command start -verb runas powershell
echo
echo "To export $name VM image to $path, run following in Admin powershell"
echo "$remove_cmd"
echo "$export_cmd"
