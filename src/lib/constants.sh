#!/usr/bin/bash

#SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
#source "$SCRIPT_DIR/guardrails.sh"

### Directory structure:
CONTACTS_DIR="contacts"
DH_MY_POINTS="dh_my_points"
DH_RECEIVED_POINTS="dh_received_points"
EMAIL="email_address.txt"
EMAIL_PASSWORD="email_password.txt"
GMI_DIR="$HOME/.mail/gmail"

ME="__me__"
MY_DIR="${CONTACTS_DIR}/${ME}"

mkdir -p "$MY_DIR"
### End of directory structure