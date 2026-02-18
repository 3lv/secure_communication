#!/usr/bin/bash
# Usage: ./send_message.sh <other_person> <message>
# Send an email with a pair of DH public points to be used for key derivation, along with the actually encrypted emssage

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/guardrails.sh"
source "$SCRIPT_DIR/lib/constants.sh"
source "$SCRIPT_DIR/lib/parse.sh"

DANGER_USER_other_person="$1"
DANGER_USER_message="$2"

other_person=$(parse_known_person "$DANGER_USER_other_person")
# TODO: Parse the message
message="$DANGER_USER_message"

other_dir="${PEOPLE_DIR}/${other_person}"
mkdir -p "$other_dir/$DH_MY_POINTS"
mkdir -p "$other_dir/$DH_RECEIVED_POINTS"
my_email_address=$(cat "$MY_DIR/$EMAIL")
other_email_address=$(cat "$other_dir/$EMAIL")

# Pick the latest DH public point of self and the other person
# Use the folder name, not the file timestamp, because the file timestamp can change when moving files around, but the folder name is fixed at creation time

my_latest_point=$(find "$other_dir/$DH_MY_POINTS" -mindepth 1 -maxdepth 1 -type d | sort -r | head -n 1)
other_latest_point=$(find "$other_dir/$DH_RECEIVED_POINTS" -mindepth 1 -maxdepth 1 -type d | sort -r | head -n 1)

my_point_timestamp=$(basename "$my_latest_point")
other_point_timestamp=$(basename "$other_latest_point")

# Derive shared secret in memory:
openssl pkeyutl \
    -derive \
    -inkey "$my_latest_point/eph_x25519_private.pem" \
    -peerkey "$other_latest_point/eph_x25519_public.pem" \
    -out /tmp/shared_secret.bin
# TODO: STORE THIS IN A SAFE PLACE IN MEMORY, NOT ON DISK

# Derive session key
session_key=$(openssl kdf -keylen 32 \
    -kdfopt digest:SHA256 \
    -kdfopt key:/tmp/shared_secret.bin \
    -kdfopt salt:handshake_salt \
    -kdfopt info:session_key \
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
    -secretkeyid 01 \
    -out ciphertext.cms \
    -outform DER

ciphertext_b64=$(base64 -w 0 ciphertext.cms | tr -d '\n')
rm ciphertext.cms

MAIL_FILE="mail.txt"
echo "-----BEGIN DH EMAIL-----" > "$MAIL_FILE"
echo "my_point_timestamp: $my_point_timestamp" >> "$MAIL_FILE"
echo "other_point_timestamp: $other_point_timestamp" >> "$MAIL_FILE"
echo "ciphertext_b64: $ciphertext_b64" >> "$MAIL_FILE"
echo "-----END DH EMAIL-----" >> "$MAIL_FILE"

echo "Sending encrypted message email..."
(
    echo "From: $my_email_address"
    echo "To: $other_email_address"
    echo "Subject: Encrypted Message"
    echo "Date: $(date -R)"
    echo
    cat "$MAIL_FILE"
) | gmi send -t -C "$GMI_DIR" >/dev/null
rm "$MAIL_FILE"

echo "Message sent successfully!"