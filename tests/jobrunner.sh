#!/bin/bash
./scripts/install.sh
./scripts/jobrunner.sh tpp-backend

# check it is running
sleep 1 # let it have chance to start up
systemctl status jobrunner
