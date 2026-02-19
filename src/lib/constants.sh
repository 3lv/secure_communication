#!/usr/bin/bash

#SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Resolve this script's absolute path reliably (works via symlink + via $PATH)
#source "$SCRIPT_DIR/guardrails.sh"

# Parameters:
DH_POINT_EXPIRATION_SECONDS=$((7 * 24 * 60 * 60)) # 7 days

# Contacts directory
#CONTACTS_DIR="contacts"
# Instead of local directory, use home
CONTACTS_DIR="$HOME/contacts"
STATE_DIR=".state"
DH_POINTS_DIR="$STATE_DIR/dh_points"
DH_MY_POINTS="$DH_POINTS_DIR/my"
DH_RECEIVED_POINTS="$DH_POINTS_DIR/received"
ME="__me__"
MY_DIR="${CONTACTS_DIR}/${ME}"

# Email related files
EMAIL="email_address.txt"
EMAIL_PASSWORD="email_password.txt"
GMI_DIR="$HOME/.mail/gmail"

# Installation:
INSTALL_DIR="/usr/local/lib/secure_communication"
BIN_DIR="/usr/local/bin"