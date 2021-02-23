#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND="noninteractive"

apt-get update
apt-get install linux-virtual
sed 's/^#.*//' tpp-backend/packages-to-remove.txt | xargs apt-get purge -y

# f-ing snaps
snap remove gnome-3-34-1804  
snap remove gtk-common-themes  
snap remove snap-store         
snap remove core18             
sudo rm -rf /var/lib/snapd/seed/*

apt-get autoremove -y
apt-get autoclean
