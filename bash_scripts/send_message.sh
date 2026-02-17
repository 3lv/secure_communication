#!/usr/bin/bash
# Usage: ./send_message.sh <other_person> <message>
# Send an email with a pair of DH public points to be used for key derivation, along with the actually encrypted emssage

set -euo pipefail
IFS=$'\n\t'

other_person="$1"
message="$2"

### Directory structure:
PEOPLE_DIR="people"
DH_MY_POINTS="dh_my_points"
DH_RECEIVED_POINTS="dh_received_points"
EMAIL="email_address.txt"
EMAIL_PASSWORD="email_password.txt"

ME="__me__"
MY_DIR="${PEOPLE_DIR}/${ME}"
OTHER_DIR="${PEOPLE_DIR}/${other_person}"

mkdir -p "$MY_DIR"
mkdir -p "$OTHER_DIR/$DH_MY_POINTS"
mkdir -p "$OTHER_DIR/$DH_RECEIVED_POINTS"
### End of directory structure

# Pick the latest DH public point of self and the other person
# Use the folder name, not the file timestamp, because the file timestamp can change when moving files around, but the folder name is fixed at creation time

#MY_LATEST_POINT=$(ls -td "$OTHER_DIR/$DH_MY_POINTS"/*/ | head -n 1)
#OTHER_LATEST_POINT=$(ls -td "$OTHER_DIR/$DH_RECEIVED_POINTS"/*/ | head -n 1)
MY_LATEST_POINT=$(find "$OTHER_DIR/$DH_MY_POINTS" -mindepth 1 -maxdepth 1 -type d | sort -r | head -n 1)
OTHER_LATEST_POINT=$(find "$OTHER_DIR/$DH_RECEIVED_POINTS" -mindepth 1 -maxdepth 1 -type d | sort -r | head -n 1)

my_point_timestamp=$(basename "$MY_LATEST_POINT")
other_point_timestamp=$(basename "$OTHER_LATEST_POINT")

# Derive shared secret in memory:
openssl pkeyutl \
    -derive \
    -inkey "$MY_LATEST_POINT/eph_x25519_private.pem" \
    -peerkey "$OTHER_LATEST_POINT/eph_x25519_public.pem" \
    -out /tmp/shared_secret.bin
# TODO: STORE THIS IN A SAFE PLACE IN MEMORY, NOT ON DISK

# Derive session key
session_key=$(openssl kdf -keylen 32 \
    -kdfopt digest:SHA256 \
    -kdfopt key:/tmp/shared_secret.bin \
    -kdfopt salt:handshake_salt \
    -kdfopt info:ssion_key \
    HKDF | tr -d '\n')

#openssl rand 12 > nonce.bin
#openssl enc -aes-256-gcm \
#    -K "$(xxd -p /tmp/session_key.bin)" \
#    -iv "$(xxd -p nonce.bin)" \
#    -in <(echo -n "$message") \
#    -out ciphertext.bin \
#    -nosalt \
#    -tag tag.bin
# TODO: Add salt
printf %s "$message" | openssl cms \
    -encrypt \
    -binary \
    -aes-256-gcm \
    -secretkey "$session_key" \
    -secretkeyid 01\
    -out ciphertext.cms \
    -outform DER \

ciphertext_b64=$(base64 -w 0 ciphertext.cms)

MAIL_FILE="mail.txt"
echo "-----BEGIN DH EMAIL-----" > "$MAIL_FILE"
echo "my_point_timestamp: $my_point_timestamp" >> "$MAIL_FILE"
echo "other_point_timestamp: $other_point_timestamp" >> "$MAIL_FILE"
echo "ciphertext_b64: $ciphertext_b64" >> "$MAIL_FILE"
echo "-----END DH EMAIL-----" >> "$MAIL_FILE"

# TODO: Send the mail.txt
#
## Make it RFC 5322 compliant by adding a From, To, Subject, and Date header
#email_address=$(cat "$MY_DIR/$EMAIL")
#other_email_address=$(cat "$OTHER_DIR/$EMAIL")
#(
#    echo "From: $email_address"
#    echo "To: $other_email_address"
#    echo "Subject: Encrypted Message"
#    echo "Date: $(date -R)"
#    echo
#    cat "$MAIL_FILE"
#) | gmi send