#!/usr/bin/bash

#SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
#source "$SCRIPT_DIR/guardrails.sh"

### Directory structure:
PEOPLE_DIR="people"
DH_MY_POINTS="dh_my_points"
DH_RECEIVED_POINTS="dh_received_points"
EMAIL="email_address.txt"
EMAIL_PASSWORD="email_password.txt"
GMI_DIR="/home/vlad/.mail/gmail"

ME="__me__"
MY_DIR="${PEOPLE_DIR}/${ME}"

mkdir -p "$MY_DIR"
### End of directory structure