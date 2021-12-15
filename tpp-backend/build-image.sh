#!/bin/bash
# This script is meant to be run in git-bash on Windows, and builds a hyper-v image
# You probably want an ssh-agent set up to run it.
# It is not fully automated, as Windows has no easy equivalent of sudo, and the
# final commands require running as Administrator. So, we launch an
# Administrator powershell and print some commands for you to copy/paste into
# it.
#
#
set -euo pipefail
name=opensafely-tpp
# path to export image to
path=${2:-D:\\}

# Use multipass to create a base Ubuntu Server Hyper-v instance.
#
# Note: this is a Gen 1 instance, as that's what multipass creates.
# Ideally, we use a Gen 2 instance simply to be more up to date, but there's no
# compelling benefits for our use case. Gen 1 supports up to 64 cors and 1TB of
# RAM, which is enough for current hardware.
#
# More information on the differences here:
# https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/plan/should-i-create-a-generation-1-or-2-virtual-machine-in-hyper-v#whats-the-difference-in-device-support
# 
# Note: the defaults are 1 cpu, 1G ram, and 5G disk
multipass info $name || multipass launch 20.04 --name $name

# Udpate and install the virtual kernel flavour, which has  hyper-v specific
# kernel modules and services. 
# Note: HWE version is important for a more recent kernel, which has better
# Hyper-V guest support.
multipass exec $name -- sudo apt-get update
multipass exec $name -- sudo apt-get upgrade -y
multipass exec $name -- sudo apt-get install -y linux-virtual-hwe-20.04 linux-tools-virtual-hwe-20.04 linux-cloud-tools-virtual-hwe-20.04

# Make sure it boots, which is important, as the installed hyper-v integration
# services will not come up properly without it, which can mean our image does
# not boot down the line.
#
# More information about integration services here:
# https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/reference/integration-services
#
multipass restart $name

# Note: multipass mount is hella weird, so we just copy.
# Copy current directory to host
tarball=../current.tar
rm -f "$tarball"
tar cvf "$tarball" --exclude-vcs .
multipass transfer "$tarball" "$name://tmp/current.tar"
multipass exec $name -- sudo mkdir -p //tmp/config
multipass exec $name -- sudo tar xvf //tmp/current.tar -C //tmp/config

vmaddress="$(multipass exec $name -- hostname -I)"
echo "IP: $vmaddress"

# configure base TPP backend
multipass exec $name -- sudo env --chdir //tmp/config SHELLOPTS=xtrace ./tpp-backend/manage.sh

# clean up any unwanted stuff in the image
# The main thing this does is reset cloud-init to re-run on next boot, but with
# our custom cloud init config from ./cloud-init
multipass exec $name -- sudo env --chdir //tmp/config SHELLOPTS=xtrace ./tpp-backend/clean-image.sh

# disable the default ubuntu user
# unfortunatlely, its very awkward for us to delete it here, due to requiring it to ssh in.
# so we simply disable it
multipass exec $name -- sudo env --chdir //tmp/config SHELLOPTS=xtrace ./tpp-backend/remove-ubuntu-user.sh

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
