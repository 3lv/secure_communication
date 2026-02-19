#!/usr/bin/bash
# Usage: ./send_dh_point.sh <other_person>
#
# This generates a new dh public point and sends it

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/guardrails.sh"
source "$SCRIPT_DIR/lib/constants.sh"
source "$SCRIPT_DIR/lib/parse.sh"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/sandbox.sh"

DANGER_USER_other_person="$1"
other_person=$(parse_known_person "$DANGER_USER_other_person")

other_dir="${CONTACTS_DIR}/${other_person}"
my_email_address=$(cat "$MY_DIR/$EMAIL")
other_email_address=$(cat "$other_dir/$EMAIL")

my_email_address=$(cat "$MY_DIR/$EMAIL")
other_email_address=$(cat "$other_dir/$EMAIL")

# Make a new dir for the new values inside MY_VALUES
TIMESTAMP=$(date +%s)
NEW_POINT="${other_dir}/${DH_MY_POINTS}/${TIMESTAMP}"
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
rm "$NEW_POINT/payload.txt" # TODO: Improve cleaning up, maybe with a cleanup function

base64 -w 0 "$NEW_POINT/eph_x25519_public.sig" > "$NEW_POINT/sig.b64"
MAIL_FILE="mail.txt"
echo "-----BEGIN DH EMAIL-----" > "$MAIL_FILE"
echo "timestamp: $TIMESTAMP" >> "$MAIL_FILE"
echo "dh_pub_b64: $(cat "$NEW_POINT/pub.b64")" >> "$MAIL_FILE"
echo "dh_sig_b64: $(cat "$NEW_POINT/sig.b64")" >> "$MAIL_FILE"
echo "-----END DH EMAIL-----" >> "$MAIL_FILE"
rm "$NEW_POINT/pub.b64" "$NEW_POINT/sig.b64"


echo "Sending DH email..."
(
    echo "From: $my_email_address"
    echo "To: $other_email_address"
    echo "Subject: DH Point Update"
    echo "Date: $(date -R)"
    echo
    cat "$MAIL_FILE"
) | sandbox_gmi_send >/dev/null
#) | gmi send -t -C "$GMI_DIR" >/dev/null
rm "$MAIL_FILE"

echo "DH point sent successfully!"