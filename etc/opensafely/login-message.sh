#!/bin/bash
set -euo pipefail

# only show this to developers
groups | grep -q developers || exit 0

# lets be obnoxious 
echo ""
echo -e "\033[5m\x1b[1;31mNOTICE: The system configuration has changed recently! READ CAREFULLY! \033[0m"
echo ""
# The above can be deleted after a bit

echo "You are logged in under your personal username."
echo ""
echo "To operate opensafely services, please switch to the shared opensafely user:"
echo "    sudo su - opensafely"
echo ""
