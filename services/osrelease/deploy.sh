#!/bin/bash
set -euo pipefail
echo "Updating osrelease..."""
git -C ./wheels pull
git -C ./code pull

./venv/bin/pip install -U --no-index --find-links ./wheels -r ./code/requirements.prod.txt
