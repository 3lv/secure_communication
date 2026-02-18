#!/usr/bin/bash
# Usage: ./init_gmail.sh <name> <gmail_address>
#
# Initializes notmuch an gmi for faster setup

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/guardrails.sh"
source "$SCRIPT_DIR/lib/constants.sh"
source "$SCRIPT_DIR/lib/parse.sh"

require_cmd openssl base64 gmi notmuch

DANGER_USER_name="$1"
name="$DANGER_USER_name"

DANGER_USER_email="$2"
email=$(parse_email "$DANGER_USER_email")

#!/bin/bash

cat > "$HOME/.notmuch-config" <<EOF
[database]
path=$GMI_DIR

[user]
name=$name
primary_email=$email

[new]
tags=new;
ignore=

[search]
exclude_tags=deleted;spam;

[maildir]
synchronize_flags=true
EOF

cd "$GMI_DIR"
notmuch new

gmi init "$email"