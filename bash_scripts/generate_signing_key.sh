#!/usr/bin/bash
# Usage: ./generate_signing_key.sh
#

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/guardrails.sh"
source "$SCRIPT_DIR/lib/constants.sh"

if [ -f "$MY_DIR/ed25519_private.pem" ] || [ -f "$MY_DIR/ed25519_public.pem" ]; then
    echo "Error: ed25519 key pair already exists in $MY_DIR!"
    exit 1
fi

mkdir -p "$MY_DIR"

openssl genpkey -algorithm ED25519 -out "$MY_DIR/ed25519_private.pem"
openssl pkey -in "$MY_DIR/ed25519_private.pem" -pubout -out "$MY_DIR/ed25519_public.pem"

echo "Key pair generated successfully"