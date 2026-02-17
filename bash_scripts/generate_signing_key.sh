#!/usr/bin/bash

PEOPLE_DIR="people"

ME="__me__"
MY_DIR="${PEOPLE_DIR}/${ME}"

mkdir -p "$MY_DIR"

openssl genpkey -algorithm ED25519 -out "$MY_DIR/ed25519_private.pem"
openssl pkey -in "$MY_DIR/ed25519_private.pem" -pubout -out "$MY_DIR/ed25519_public.pem"

# TODO: Manage permisions

echo "Key pair generated successfully"