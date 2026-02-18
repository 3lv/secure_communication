#!/usr/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091 #Sourcing the groudrails relative to the script dir
source "$SCRIPT_DIR/lib/guardrails.sh"
safe_source "lib/constants.sh"

if [ -f "$MY_DIR/ed25519_private.pem" ] || [ -f "$MY_DIR/ed25519_public.pem" ]; then
    echo "Error: ed25519 key pair already exists in $MY_DIR!"
    exit 1
fi

mkdir -p "$MY_DIR"

openssl genpkey -algorithm ED25519 -out "$MY_DIR/ed25519_private.pem"
openssl pkey -in "$MY_DIR/ed25519_private.pem" -pubout -out "$MY_DIR/ed25519_public.pem"

# TODO: Manage permisions

echo "Key pair generated successfully"