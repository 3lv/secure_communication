#!/usr/bin/bash
# Usage: ./send_dh_point.sh <other_person>
# This generates a new dh public point and sends it

set -euo pipefail
IFS=$'\n\t'

other_person="$1"

### Directory structure:
PEOPLE_DIR="people"
DH_MY_POINTS="dh_my_points"
DH_RECEIVED_POINTS="dh_received_points"
EMAIL="email_address.txt"
EMAIL_PASSWORD="email_password.txt"
GMI_DIR="/home/vlad/.mail/gmail"

ME="__me__"
MY_DIR="${PEOPLE_DIR}/${ME}"
OTHER_DIR="${PEOPLE_DIR}/${other_person}"

mkdir -p "$MY_DIR"
mkdir -p "$OTHER_DIR/$DH_MY_POINTS"
mkdir -p "$OTHER_DIR/$DH_RECEIVED_POINTS"
### End of directory structure

# Make a new dir for the new values inside MY_VALUES
TIMESTAMP=$(date +%s)
NEW_POINT="${OTHER_DIR}/${DH_MY_POINTS}/${TIMESTAMP}"
mkdir -p "$NEW_POINT"

# Generate it
openssl genpkey -algorithm X25519 -out "$NEW_POINT/eph_x25519_private.pem"
openssl pkey -in "$NEW_POINT/eph_x25519_private.pem" -pubout -out "$NEW_POINT/eph_x25519_public.pem"
base64 -w 0 "$NEW_POINT/eph_x25519_public.pem" > "$NEW_POINT/pub.b64"

# Create payload to sign(timestamp + public point)
echo "timestamp: $TIMESTAMP" > "$NEW_POINT/payload.txt"
echo "dh_pub_b64: $(cat "$NEW_POINT/pub.b64")" >> "$NEW_POINT/payload.txt"
# TODO: Also add sender, receiver here and in the mail

# Sign the payload
openssl pkeyutl \
    -sign \
    -inkey "$MY_DIR/ed25519_private.pem" \
    -rawin \
    -in "$NEW_POINT/payload.txt" \
    -out "$NEW_POINT/eph_x25519_public.sig"
base64 -w 0 "$NEW_POINT/eph_x25519_public.sig" > "$NEW_POINT/sig.b64"

MAIL_FILE="mail.txt"
echo "-----BEGIN DH EMAIL-----" > "$MAIL_FILE"
echo "timestamp: $TIMESTAMP" >> "$MAIL_FILE"
echo "dh_pub_b64: $(cat "$NEW_POINT/pub.b64")" >> "$MAIL_FILE"
echo "dh_sig_b64: $(cat "$NEW_POINT/sig.b64")" >> "$MAIL_FILE"
echo "-----END DH EMAIL-----" >> "$MAIL_FILE"

cat "$MAIL_FILE"

# Send the mail.txt via email using curl
email_address=$(cat "$MY_DIR/$EMAIL")
other_email_address=$(cat "$OTHER_DIR/$EMAIL")
(
    echo "From: $email_address"
    echo "To: $other_email_address"
    echo "Subject: DH Point Update"
    echo "Date: $(date -R)"
    echo
    cat "$MAIL_FILE"
) | gmi send -t -C "$GMI_DIR"

echo "DH point sent successfully!"