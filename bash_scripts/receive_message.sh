#!/usr/bin/bash
# Usage: ./receive_message.sh <other_person>
# This script is run after receiving an email, checks the DH public
# points used and decrypt + check the integrity of the message,
# then prints it

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091 #Sourcing the groudrails relative to the script dir
source "$SCRIPT_DIR/lib/guardrails.sh"
source "$SCRIPT_DIR/lib/constants.sh"

other_person="$1"
other_dir="${PEOPLE_DIR}/${other_person}"
mkdir -p "$other_dir/$DH_MY_POINTS"
mkdir -p "$other_dir/$DH_RECEIVED_POINTS"
other_email_address=$(cat "$other_dir/$EMAIL")


#mail_file="mail.txt"
gmi pull -C "$GMI_DIR"
mail_file="$(notmuch search --output=files --sort=newest-first \
  "from:$other_email_address subject:\"Encrypted Message\"" | head -n 1)"
if [ -z "$mail_file" ]; then
    echo "No email found from $other_person with subject \"Encrypted Message\""
    exit 1
fi

# Parse the email content, extract the my_point_timestamp, other_point_timestamp and ciphertext_b64
#MAIL_FILE="mail.txt"
# Reverse the points (from our perspective, their "my_point" is our "other_point" etc)
other_point_timestamp=$(grep "my_point_timestamp: " "$mail_file" | cut -d' ' -f2)
my_point_timestamp=$(grep "other_point_timestamp: " "$mail_file" | cut -d' ' -f2)
ciphertext_b64=$(grep "ciphertext_b64: " "$mail_file" | cut -d' ' -f2)

# Check if the other_point and my_point are the same as the ones we have in the $OTHER_DIR, if not, reject the message
# Check if toher_dir exists
if [ ! -d "$other_dir" ]; then
    echo "Error: You don't have $other_person in your agenda people agenda!"
    exit 1
fi

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
if [ -f "$MY_DIR/$DH_MY_POINTS/$my_point_timestamp/eph_x25519_public.pem" ]; then
    found_my_point=1
    found_my_point_dir="$MY_DIR/$DH_MY_POINTS/$my_point_timestamp"
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

openssl cms \
  -decrypt \
  -binary \
  -secretkey "$session_key" \
  -inform DER \
  -in /tmp/ciphertext.cms \
  #-out decrypted.txt

#cat decrypted.txt
echo