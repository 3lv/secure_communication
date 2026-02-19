#!/usr/bin/bash
# Usage: ./receive_message.sh <other_person>
#
# This script is run after receiving an email, checks the DH public
# points used and decrypt + check the integrity of the message,
# then prints it

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/guardrails.sh"
source "$SCRIPT_DIR/lib/constants.sh"
source "$SCRIPT_DIR/lib/parse.sh"

DANGER_USER_other_person="$1"
other_person=$(parse_known_person "$DANGER_USER_other_person")

other_dir="${CONTACTS_DIR}/${other_person}"
other_email_address=$(cat "$other_dir/$EMAIL")

#mail_file="mail.txt"
echo "Fetching emails from $other_person..."
gmi pull -C "$GMI_DIR" >/dev/null
DANGER_FROM_NETWORK_mail_file="$(notmuch search --output=files --sort=newest-first \
  "from:$other_email_address subject:\"Encrypted Message\"" | head -n 1)"
# DANGER explained:
#  - File can actually not exist
#  - File can contain anything
if [ -z "$DANGER_FROM_NETWORK_mail_file" ]; then
    die "No email found from $other_person with subject \"Encrypted Message\""
fi
echo "Got latest 'Encrypted Message' email from $other_person"

# Parse the email content, extract the my_point_timestamp, other_point_timestamp and ciphertext_b64
#MAIL_FILE="mail.txt"
# Reverse the points (from our perspective, their "my_point" is our "other_point" etc)
DANGER_FROM_NETWORK_other_point_timestamp=$(grep "my_point_timestamp: " "$DANGER_FROM_NETWORK_mail_file" | cut -d' ' -f2)
DANGER_FROM_NETWORK_my_point_timestamp=$(grep "other_point_timestamp: " "$DANGER_FROM_NETWORK_mail_file" | cut -d' ' -f2)
#DANGER_FROM_NETWORK_ciphertext_b64=$(grep "ciphertext_b64: " "$DANGER_FROM_NETWORK_mail_file" | cut -d' ' -f2)
# TODO: Improve this parsing. Currently gmail can insert newlines in the base64,
#   moving the ciphertext value to the next line
DANGER_FROM_NETWORK_ciphertext_b64=$(grep -A1 "ciphertext_b64:" "$DANGER_FROM_NETWORK_mail_file" | tail -n1)

my_point_timestamp=$(parse_timestamp "$DANGER_FROM_NETWORK_my_point_timestamp")
other_point_timestamp=$(parse_timestamp "$DANGER_FROM_NETWORK_other_point_timestamp")
ciphertext_b64=$(parse_b64 "$DANGER_FROM_NETWORK_ciphertext_b64" 10 1000000)


# TODO: Use point hash instead of timestamp, similar to the commented code
#found_other_point=0
#found_other_point_dir=""
#for dir in "$other_dir/$DH_RECEIVED_POINTS"/*/; do
#    if [ -f "$dir/eph_x25519_public.pem" ]; then
#        existing_other_point_b64=$(base64 -w 0 "$dir/eph_x25519_public.pem")
#        if [ "$existing_other_point_b64" == "$other_point_b64" ]; then
#            found_other_point=1
#            found_other_point_dir="$dir"
#            break
#        fi
#    fi
#done
found_other_point=0
found_other_point_dir=""
if [ -f "$other_dir/$DH_RECEIVED_POINTS/$other_point_timestamp/eph_x25519_public.pem" ]; then
    found_other_point=1
    found_other_point_dir="$other_dir/$DH_RECEIVED_POINTS/$other_point_timestamp"
fi
if [ $found_other_point -ne 1 ]; then
    echo "ERROR"
    echo "Other point does not match any known public points for $other_person"
    echo "He is either lying or the point expired and he is still reusing it"
    exit 1
fi

# Check the same for my_point_b64, check if it exists in any of the $OTHER_DIR/$DH_MY_POINTS/*/eph_x25519_public.pem
#found_my_point=0
#found_my_point_dir=""
#for dir in "$MY_DIR/$DH_MY_POINTS"/*/; do
#    if [ -f "$dir/eph_x25519_public.pem" ]; then
#        #existing_my_point_b64=$(base64 -w 0 "$dir/eph_x25519_public.pem")
#        #if [ "$existing_my_point_b64" == "$my_point_b64" ]; then
#        found_my_point=1
#        found_my_point_dir="$dir"
#        break
#        #fi
#    fi
#done
found_my_point=0
found_my_point_dir=""
if [ -f "$other_dir/$DH_MY_POINTS/$my_point_timestamp/eph_x25519_public.pem" ]; then
    found_my_point=1
    found_my_point_dir="$other_dir/$DH_MY_POINTS/$my_point_timestamp"
fi
if [ $found_my_point -ne 1 ]; then
    echo "ERROR"
    echo "My point does not match any known public points for $other_person"
    echo "He is either lying or the point expired and he is still reusing it"
    exit 1
fi


# At this point they were both found, we can compute the shared secret
openssl pkeyutl \
    -derive \
    -inkey "$found_my_point_dir/eph_x25519_private.pem" \
    -peerkey "$found_other_point_dir/eph_x25519_public.pem" \
    -out /tmp/shared_secret.bin

# Derive session key
session_key=$(openssl kdf -keylen 32 \
    -kdfopt digest:SHA256 \
    -kdfopt key:/tmp/shared_secret.bin \
    -kdfopt salt:handshake_salt \
    -kdfopt info:session_key \
    HKDF | tr -d '\n')


# Create the ciphertext.cms from the ciphertext_b64
echo "$ciphertext_b64" | base64 -d > /tmp/ciphertext.cms

decrypted_message=$(openssl cms \
  -decrypt \
  -binary \
  -secretkey "$session_key" \
  -inform DER \
  -in /tmp/ciphertext.cms \
)
rm /tmp/ciphertext.cms

echo "$decrypted_message"
# Not having this $decrypted_message stored anywhere and having the
# eph_x25519_private.pem removed from the both sides,
# make the message unrecoverable