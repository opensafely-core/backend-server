#!/bin/bash
set -euo pipefail

CONFIG_SRC_DIR=config
HOME_DIR=/home/opensafely

extract_keys() {
  ENV_FILE=$1
  grep -v "\(^#\|^\w*$\)" "$ENV_FILE" | cut -f 1 -d'=' | sort 
}

secrets_env="$HOME_DIR/config/02_secrets.env"
TEMPLATE_SECRETS_FILE="$CONFIG_SRC_DIR/secrets-template.env"
LIVE_SECRETS_FILE=$secrets_env

echo "Verifying contents of $secrets_env against template"
echo "------"
echo "Keys only present in template:"
comm -23 <(extract_keys "$TEMPLATE_SECRETS_FILE") <(extract_keys "$LIVE_SECRETS_FILE")
echo "------"

echo "Keys only present in $secrets_env:"
comm -13 <(extract_keys "$TEMPLATE_SECRETS_FILE") <(extract_keys "$LIVE_SECRETS_FILE")
echo "------"
