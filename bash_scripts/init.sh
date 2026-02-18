#!/usr/bin/bash
# Usage: ./init.sh <gmail_address>
#
# Initializes directory structure and generates signing key pair for the user

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/guardrails.sh"
source "$SCRIPT_DIR/lib/constants.sh"
source "$SCRIPT_DIR/lib/parse.sh"
required_commands openssl base64 gmi notmuch

DANGER_USER_email="$1"

email=$(parse_email "$DANGER_USER_email")

mkdir -p "$MY_DIR"

echo "$email" > "$MY_DIR/$EMAIL"

./generate_signing_key.sh