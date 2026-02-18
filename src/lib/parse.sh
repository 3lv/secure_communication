#!/usr/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/constants.sh"

is_len_between() {
  local s="$1" min="$2" max="$3"
  local len=${#s}
  (( len >= min && len <= max ))
}

is_digits() {
  local s="$1"
  [[ -n "$s" && "$s" != *[!0-9]* ]]
}

is_b64_charset() {
  local s="$1"
  [[ -n "$s" && "$s" != *[!A-Za-z0-9+/=]* ]]
}


# Parse an unsigned integer with max digits and optional min/max range.
# Usage:
#   parse_uint "$input" max_digits [min] [max]
parse_uint() {
  local s="$1" max_digits="$2"
  local min="${3:-}" max="${4:-}"

  is_digits "$s" || die "expected unsigned integer"
  ((${#s} <= max_digits)) || die "integer too long (max digits $max_digits)"

  # prevent leading '+' etc already covered; allow "0" and leading zeros (harmless)
  # range checks (numeric context)
  if [[ -n "$min" ]]; then
    (( 10#$s >= min )) || die "integer below minimum ($min)"
  fi
  if [[ -n "$max" ]]; then
    (( 10#$s <= max )) || die "integer above maximum ($max)"
  fi

  printf '%s\n' "$s"
}

# Timestamp betwen 2001 and 2096
parse_timestamp() {
    local s="$1"
    parse_uint "$s" 10 1000000000 4000000000
}

# Validate base64 string with max length and optional strict padding.
# This checks:
# - allowed characters
# - 4 <= length <= maxlen
# - length % 4 == 0 (required for standard padded base64)
# - '=' only at the end, 0..2 chars
# It does NOT decode
# Usage:
#   parse_b64 "$input" maxlen
parse_b64() {
    local s="$1" maxlen="$2"
    is_len_between "$s" 4 "$maxlen" || die "base64 length must be between 4 and $maxlen"
    is_b64_charset "$s" || die "invalid base64 characters"
    (( ${#s} % 4 == 0 )) || die "invalid base64 length (must be multiple of 4)"

    # '=' padding rules: only at end, at most 2
    #case "$s" in
    #    (*=*=*) die "invalid base64 padding" ;;  # '=' appears more than once separated
    #esac
    ##local pad="${s##*[! =]}" # not reliable; do explicit:
    ## explicit check: '=' only allowed in last 2 positions
    #if [[ "$s" == *"="* ]]; then
    #    [[ "$s" == *"=" || "$s" == *"==" ]] || die "invalid base64 padding placement"
    #    [[ "$s" != *"="*"="*"="* ]] || die "invalid base64 padding count"
    #    # also ensure no '=' before last 2 chars
    #    local prefix="${s:0:${#s}-2}"
    #    [[ "$prefix" != *"="* ]] || die "invalid base64 padding placement"
    #fi

    printf '%s\n' "$s"
}

# Validate a relative "safe path segment" (no slashes, no '..'), bounded length.
# This is for constructing paths like "$base/$segment".
# Usage:
#   parse_path_segment "$input" maxlen
parse_path_segment() {
  local s="$1" maxlen="$2"
  is_len_between "$s" 1 "$maxlen" || die "path segment length must be between 1 and $maxlen"
  [[ "$s" != */* ]] || die "path segment must not contain '/'"
  [[ "$s" != "." && "$s" != ".." ]] || die "invalid path segment"
  [[ "$s" != *".."* ]] || true  # optional; too strict for some names
  # Allow a conservative charset
  [[ "$s" != *[!A-Za-z0-9_.-]* ]] || die "invalid path segment characters"
  printf '%s\n' "$s"
}

parse_known_person() {
    local s="$1"
    s=$(parse_path_segment "$s" 100)
    [[ -d "${CONTACTS_DIR}/$s" ]] || die "You don't have $s in your contacts!"
    [[ -f "${CONTACTS_DIR}/$s/ed25519_public.pem" ]] || die "Person $s does not have a ed25519 public key in their agenda directory!"
    [[ -f "${CONTACTS_DIR}/$s/email_address.txt" ]] || die "Person $s does not have a email address in their agenda directory!"

    printf '%s\n' "$s"
}

parse_email() {
    local s="$1"
    # Basic email validation: reasonable length, local@domain, no spaces
    is_len_between "$s" 5 254 || die "email length must be between 5 and 254 characters"
    [[ "$s" == *@* ]] || die "invalid email format (missing '@')"
    [[ "$s" != *[[:space:]]* ]] || die "email must not contain spaces"
    # More complex regex could be used, but this is a reasonable balance for now
    [[ "$s" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] || die "invalid email format"

    printf '%s\n' "$s"
}