#!/usr/bin/bash
# Usage: ./add_person.sh <name> <email_address>


SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/guardrails.sh"
source "$SCRIPT_DIR/lib/constants.sh"
source "$SCRIPT_DIR/lib/parse.sh"
required_commands openssl base64 gmi notmuch

DANGER_USER_name="$1"
DANGER_USER_email="$2"

DANGER_USER_name="$(parse_name "$DANGER_USER_name")"
# If user already exists
if [ -d "$PEOPLE_DIR/$DANGER_USER_name" ]; then
    echo "Error: User '$DANGER_USER_name' already exists."
    exit 1
fi
name="$DANGER_USER_name"
email="$(parse_email "$DANGER_USER_email")"

other_dir="$PEOPLE_DIR/$name"
mkdir -p "$other_dir"
# Add email
echo "$email" > "$other_dir/$MAIL"
