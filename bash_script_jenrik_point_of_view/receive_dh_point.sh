#!/usr/bin/bash
# Usage: ./receive_dh_point.sh <other_person>

# Pulls emails from <other_person> and parses the DH public point, verifies the signature, and saves it

set -euo pipefail
IFS=$'\n\t'

other_person="$1"

# Directory structure:
PEOPLE_DIR="people"
DH_MY_POINTS="dh_my_points"
DH_RECEIVED_POINTS="dh_received_points"
EMAIL="email_address.txt"
EMAIL_PASSWORD="email_password.txt"

ME="__me__"
MY_DIR="${PEOPLE_DIR}/${ME}"
OTHER_DIR="${PEOPLE_DIR}/${other_person}"

# Somehow get the email
MAIL_FILE="mail.txt"

# This is how the email is expected to be formatted, the send_dh_point.sh script composes it like this:
#echo "-----BEGIN DH EMAIL-----" > mail.txt
#echo "timestamp: $TIMESTAMP" >> mail.txt
#echo "dh_pub_b64: $(cat "$NEW_POINT/pub.b64")" >> mail.txt
#echo "dh_sig_b64: $(cat "$NEW_POINT/sig.b64")" >> mail.txt
#echo "-----END DH EMAIL-----" >> mail.txt

# Parse into timestamp, public_point_b64 and signature_b64
timestamp=$(grep "timestamp: " "$MAIL_FILE" | cut -d' ' -f2)
public_point_b64=$(grep "dh_pub_b64: " "$MAIL_FILE" | cut -d' ' -f2)
signature_b64=$(grep "dh_sig_b64: " "$MAIL_FILE" | cut -d' ' -f2)

NEW_POINT="${other_person}/${DH_RECEIVED_POINTS}/${timestamp}"
POTENTIAL_NEW_POINT="/tmp/${other_person}_${timestamp}"
mkdir -p "$POTENTIAL_NEW_POINT"

# Save to temp file before verifying with openssl
echo "$public_point_b64" | base64 -d > "$POTENTIAL_NEW_POINT/received_pub.pem"
echo "$signature_b64" | base64 -d > "$POTENTIAL_NEW_POINT/received_sig.bin"

# Create the payload to verify (timestamp + public point)
echo "timestamp: $timestamp" > "$POTENTIAL_NEW_POINT/payload.txt"
echo "dh_pub_b64: $public_point_b64" >> "$POTENTIAL_NEW_POINT/payload.txt"

# Verify the signature
openssl pkeyutl \
    -verify \
    -pubin \
    -inkey "$OTHER_DIR/ed25519_public.pem" \
    -rawin \
    -in "$POTENTIAL_NEW_POINT/payload.txt" \
    -sigfile "$POTENTIAL_NEW_POINT/received_sig.bin"

# Check if code 0
#if [ $? -ne 0 ]; then
#    echo "Signature verification failed"
#    exit 1
#fi

# Actually save it to the right place
mkdir -p "${OTHER_DIR}/${DH_RECEIVED_POINTS}/${timestamp}"
mv "$POTENTIAL_NEW_POINT/received_pub.pem" "${OTHER_DIR}/${DH_RECEIVED_POINTS}/${timestamp}/eph_x25519_public.pem"
mv "$POTENTIAL_NEW_POINT/received_sig.bin" "${OTHER_DIR}/${DH_RECEIVED_POINTS}/${timestamp}/eph_x25519_public.sig"