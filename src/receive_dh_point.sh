#!/usr/bin/bash
# Usage: ./receive_dh_point.sh <other_person>
#
# Pulls emails from <other_person> and parses the DH public point, verifies the signature, and saves it

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/guardrails.sh"
source "$SCRIPT_DIR/lib/constants.sh"
source "$SCRIPT_DIR/lib/parse.sh"

DANGER_USER_other_person="$1"
other_person=$(parse_known_person "$DANGER_USER_other_person")

other_dir="${CONTACTS_DIR}/${other_person}"
mkdir -p "$other_dir/$DH_MY_POINTS"
mkdir -p "$other_dir/$DH_RECEIVED_POINTS"
other_email_address=$(cat "$other_dir/$EMAIL")

echo "Fetching emails from $other_person..."
gmi pull -C "$GMI_DIR" >/dev/null

DANGER_NETWORK_mail_file="$(notmuch search --output=files --sort=newest-first \
  "from:$other_email_address subject:\"DH Point Update\"" | head -n 1)"
if [ -z "$DANGER_NETWORK_mail_file" ]; then
    die "No email found from $other_person with subject \"DH Point Update\""
fi
echo "Got latest 'DH Point Update' email from $other_person"

#mail_file="mail.txt"
#mail_content=$(cat "$mail_file")
#echo "$mail_content"

# This is how the email is expected to be formatted, the send_dh_point.sh script composes it like this:
#echo "-----BEGIN DH EMAIL-----" > mail.txt
#echo "timestamp: $TIMESTAMP" >> mail.txt
#echo "dh_pub_b64: $(cat "$NEW_POINT/pub.b64")" >> mail.txt
#echo "dh_sig_b64: $(cat "$NEW_POINT/sig.b64")" >> mail.txt
#echo "-----END DH EMAIL-----" >> mail.txt
# TODO: Improve parsing security by checking the structure (and order of fields)

DANGER_NETWORK_timestamp=$(grep "timestamp: " "$DANGER_NETWORK_mail_file" | cut -d' ' -f2)
DANGER_NETWORK_public_point_b64=$(grep "dh_pub_b64: " "$DANGER_NETWORK_mail_file" | cut -d' ' -f2)
DANGER_NETWORK_signature_b64=$(grep "dh_sig_b64: " "$DANGER_NETWORK_mail_file" | cut -d' ' -f2)

timestamp=$(parse_timestamp "$DANGER_NETWORK_timestamp")
public_point_b64=$(parse_b64 "$DANGER_NETWORK_public_point_b64" 1000)
signature_b64=$(parse_b64 "$DANGER_NETWORK_signature_b64" 1000)

new_point="${other_dir}/${DH_RECEIVED_POINTS}/${timestamp}"
if [ -d "$new_point" ]; then
    die "A point with timestamp $timestamp already exists, possibly no new point or replay attack"
fi
#POTENTIAL_NEW_POINT="/tmp/${other_person}_${timestamp}"
POTENTIAL_NEW_POINT="$(mktemp -d)"
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
    -inkey "$other_dir/ed25519_public.pem" \
    -rawin \
    -in "$POTENTIAL_NEW_POINT/payload.txt" \
    -sigfile "$POTENTIAL_NEW_POINT/received_sig.bin"


mkdir -p "$new_point"
mv "$POTENTIAL_NEW_POINT/received_pub.pem" "$new_point/eph_x25519_public.pem"
mv "$POTENTIAL_NEW_POINT/received_sig.bin" "$new_point/eph_x25519_public.sig"
rm -rf "$POTENTIAL_NEW_POINT"

echo "Successfully received point from $other_person"