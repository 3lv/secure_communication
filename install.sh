#!/usr/bin/bash
# Usage: ./install.sh
#
# This script install the scripts to /usr/local/lib/secure_communication and creates symlinks in /usr/local/bin for easy access.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/src/lib/constants.sh"

# Create installation directory
sudo mkdir -p "$INSTALL_DIR"
# Copy all scripts to the installation directory
sudo cp -r "$SCRIPT_DIR/src/"* "$INSTALL_DIR/"
# Create symlinks for the main scripts in /usr/local/bin
sudo ln -sf "$INSTALL_DIR/api/clear_old_points.sh" "$BIN_DIR/sc_clear_old_points"
sudo ln -sf "$INSTALL_DIR/api/MALICIOUS_clear_old_points.sh" "$BIN_DIR/sc_MALICIOUS_clear_old_points"
sudo ln -sf "$INSTALL_DIR/api/clear_old_points.sh" "$BIN_DIR/sc_clear_old_points"
