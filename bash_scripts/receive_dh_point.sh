#!/usr/bin/bash
# Usage: ./receive_dh_point.sh <other_person>

# Pulls emails from <other_person> and parses the DH public point, verifies the signature, and saves it

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091 #Sourcing the groudrails relative to the script dir
source "$SCRIPT_DIR/lib/guardrails.sh"
source "$SCRIPT_DIR/lib/constants.sh"

other_person="$1"

other_dir="${PEOPLE_DIR}/${other_person}"
mkdir -p "$other_dir/$DH_MY_POINTS"
mkdir -p "$other_dir/$DH_RECEIVED_POINTS"
other_email_address=$(cat "$other_dir/$EMAIL")

gmi pull -C "$GMI_DIR"
mail_file="$(notmuch search --output=files --sort=newest-first \
  "from:$other_email_address subject:\"DH Point Update\"" | head -n 1)"
if [ -z "$mail_file" ]; then
    echo "No email found from $other_person with subject \"DH Point Update\""
    exit 1
fi

#mail_file="mail.txt"
#mail_content=$(cat "$mail_file")
#echo "$mail_content"

# This is how the email is expected to be formatted, the send_dh_point.sh script composes it like this:
#echo "-----BEGIN DH EMAIL-----" > mail.txt
#echo "timestamp: $TIMESTAMP" >> mail.txt
#echo "dh_pub_b64: $(cat "$NEW_POINT/pub.b64")" >> mail.txt
#echo "dh_sig_b64: $(cat "$NEW_POINT/sig.b64")" >> mail.txt
#echo "-----END DH EMAIL-----" >> mail.txt

# Parse into timestamp, public_point_b64 and signature_b64
# TODO: Improve parsing security
timestamp=$(grep "timestamp: " "$mail_file" | cut -d' ' -f2)
public_point_b64=$(grep "dh_pub_b64: " "$mail_file" | cut -d' ' -f2)
signature_b64=$(grep "dh_sig_b64: " "$mail_file" | cut -d' ' -f2)
# TODO: Enfore parsing length and format and also check missing fields

echo timestamp: "$timestamp"
echo public_point_b64: "$public_point_b64"
echo signature_b64: "$signature_b64"

NEW_POINT="${other_dir}/${DH_RECEIVED_POINTS}/${timestamp}"
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


mkdir -p "${other_dir}/${DH_RECEIVED_POINTS}/${timestamp}"
mv "$POTENTIAL_NEW_POINT/received_pub.pem" "$NEW_POINT/eph_x25519_public.pem"
mv "$POTENTIAL_NEW_POINT/received_sig.bin" "$NEW_POINT/eph_x25519_public.sig"