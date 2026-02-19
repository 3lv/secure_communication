#!/usr/bin/bash

# Always use shellcheck for static analysis of bash scripts, it can catch many common mistakes and security issues.

# set +x: Disable debugging output(i.e printing each command before executing it)
# set -e: Exit immediately if a command exits with a non-zero status.
# set -u: Treat unset variables as an error when substituting.
#   (Doesn't fail when setting the variable to the output of some
#    command, and that command returns the empty string)
# set -o pipefail: The return value of a pipeline is the status of the
#   of the last command to exit with a non-zero status, or zero if no command
#   exited with a non-zero status.
#   if cmd; then ... suppresses -e exits inside certain constructs
#   cmd || true hides failure

set +x -euo pipefail

# IFS=$'\n\t' sets the Internal Field Separator to newline and tab,
# which helps to handle filenames with spaces correctly.
# Example:
#  If IFS is not set to $'\n\t', and you have a file named "my file.txt",
# then a loop like `for file in *; do echo "$file"; done` would output:
#  my file.txt
IFS=$'\n\t'

# umask 077 sets the default permissions for new files to be readable and writable only by the owner.
umask 077

# LC_ALL=C sets the locale to the default "C" locale, which can help
#   to ensure consistent behavior across different environments.
#   (Especially regex and sorting behavior)
LC_ALL=C
export LC_ALL

# PATH='...' sets the PATH variable so it can't be modified by a user before to include malicious directories.
PATH='/usr/sbin:/usr/bin:/sbin:/bin'
export PATH

# Whenever sourcing a file, to it relative to the current script, not the current working directory.
# 
#safe_source() {
#    current_script_dir() {
#        local script_path="${BASH_SOURCE[0]}"
#        local script_dir
#        script_dir="$(dirname "$script_path")"
#        echo "$script_dir"
#    }
#    local file_path="$1"
#    if [ -f "$file_path" ]; then
#        # shellcheck disable=SC1090
#        source "$(current_script_dir)/$file_path"
#    else
#        die "Error: File $file_path not found!"
#    fi
#}
#
# Use this to source files
# SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# # shellcheck disable=SC1091 #Sourcing the groudrails relative to the script dir
# source "$SCRIPT_DIR/lib/guardrails.sh"
# source "$SCRIPT_DIR/lib/constants.sh"


# die is a helper function to print an error message and exit with a non-zero status.
#  Always better than just "exit 1" because it gives context about what went wrong.
die(){ printf 'fatal: %s\n' "$*" >&2; exit 1; }

# Check if all the dependencies are installed
require_cmd() {
  local c
  for c in "$@"; do
    command -v -- "$c" >/dev/null 2>&1 || die "missing required command: $c"
  done
}

# All user inputs should be validated before usage.
#   Because of that, all user inputs variables will start with USER_INPUT_
#   to make it clear that they need to be validated before usage.
#   This does not improve the theoretical security, but if code is not altered,
#   it can help not to shoot yourself in the foot by accidentally using bad input
DANGER_USER_variable_name="VARIABLE FROM USER INPUT, MUST BE VALIDATED BEFORE USAGE"
# All variables that come from the network are considered dangerous, they require strict validation
DANGER_NETWORK_variable_name="VARIABLE FROM NETWORK, MUST BE VALIDATED BEFORE USAGE"

# Ofc, never use eval or similar functions to execute anything that can be related to user input,
#   there has to be some better alternative
# Option injection should not be a problem as long as the input is not coming from the user
#   i.e: rm "$file" can become "rm -rf / --no-preserve-root" if $file is not validated

# TODO: Improve this:
# Writes to predictable locations shuuld be avoided, such as /tmp, home directory, etc.
#   use tmp=$(mktemp -d) to create a temporary directory with a random name, and then clean it up after usage
# Also, make sure you don't write secrets to disk
# Write to fd instead
#exec 3<<<"$secret"                 # FD 3 holds the secret
#some_command --secret-file /proc/self/fd/3
#exec 3<&-                          # close FD 3

# Passing secrets as CLI args is insecure, because they can be seen in the process list by other users.
# Instead, ...
# /proc/<pid>/cmdline can list the full command including secret arguments
# /proc/<pid>/environ can list environment variables, which can also contain secrets
# Mount /proc with hidepid=2 to prevent other users from seeing the process details of processes they don't own.
#   Does not hide from root ofc
# TODO: Complete this policy


# Use set -x for debugging 