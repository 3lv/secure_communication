#!/usr/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/guardrails.sh"
source "$SCRIPT_DIR/constants.sh"

sandbox_gmi_send() {
#   systemd-run --user --quiet --pipe --wait \
    # -p "NoNewPrivileges=yes" \
    # -p "PrivateTmp=yes" \
    # -p "PrivateDevices=yes" \
    # -p "ProtectSystem=strict" \
    # -p "ProtectHome=yes" \
    # -p "ReadWritePaths=$GMI_DIR" \
    # -p "WorkingDirectory=$GMI_DIR" \
    # -p "UMask=0077" \
    # -p "RestrictSUIDSGID=yes" \
    # -p "CapabilityBoundingSet=" \
    # -p "LockPersonality=yes" \
    # -p "MemoryDenyWriteExecute=yes" \
    # -p "RestrictNamespaces=yes" \
    # -p "RestrictRealtime=yes" \
    # -p "RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6" \
    # -p "ProtectProc=invisible" \
    # -p "ProcSubset=pid" \
    # -- /usr/bin/gmi send -t -C "$GMI_DIR"
    systemd-run --user --quiet --pipe --wait \
        -p "NoNewPrivileges=yes" \
        -p "PrivateTmp=yes" \
        -p "PrivateDevices=yes" \
        -p "ProtectSystem=strict" \
        -p "ProtectHome=yes" \
        -p "Environment=HOME=$GMI_DIR" \
        -p "Environment=XDG_DATA_HOME=$GMI_DIR" \
        -p "BindReadOnlyPaths=$HOME/.notmuch-config:$GMI_DIR/.notmuch-config" \
        -p "ReadWritePaths=$GMI_DIR" \
        -p "WorkingDirectory=$GMI_DIR" \
        -p "UMask=0077" \
        -p "RestrictSUIDSGID=yes" \
        -p "CapabilityBoundingSet=" \
        -p "LockPersonality=yes" \
        -p "MemoryDenyWriteExecute=yes" \
        -p "RestrictNamespaces=yes" \
        -p "RestrictRealtime=yes" \
        -p "ProtectKernelTunables=yes" \
        -p "ProtectControlGroups=yes" \
        -p "ProtectClock=yes" \
        -p "ProtectHostname=yes" \
        -p "RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6" \
        -p "ProtectProc=invisible" \
        -p "ProcSubset=pid" \
        -- gmi send -t -C "$GMI_DIR"
    #gmi send -t -C "$GMI_DIR"
}

sandbox_gmi_pull() {
    systemd-run --user --quiet --pipe --wait \
        -p "NoNewPrivileges=yes" \
        -p "PrivateTmp=yes" \
        -p "PrivateDevices=yes" \
        -p "ProtectSystem=strict" \
        -p "ProtectHome=yes" \
        -p "Environment=HOME=$GMI_DIR" \
        -p "Environment=XDG_DATA_HOME=$GMI_DIR" \
        -p "BindReadOnlyPaths=$HOME/.notmuch-config:$GMI_DIR/.notmuch-config" \
        -p "ReadWritePaths=$GMI_DIR" \
        -p "WorkingDirectory=$GMI_DIR" \
        -p "UMask=0077" \
        -p "RestrictSUIDSGID=yes" \
        -p "CapabilityBoundingSet=" \
        -p "LockPersonality=yes" \
        -p "MemoryDenyWriteExecute=yes" \
        -p "RestrictNamespaces=yes" \
        -p "RestrictRealtime=yes" \
        -p "ProtectKernelTunables=yes" \
        -p "ProtectControlGroups=yes" \
        -p "ProtectClock=yes" \
        -p "ProtectHostname=yes" \
        -p "RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6" \
        -p "ProtectProc=invisible" \
        -p "ProcSubset=pid" \
        -- gmi pull -C "$GMI_DIR"
}
sandbox_notmuch_search() {
    systemd-run --user --quiet --pipe --wait \
        -p "NoNewPrivileges=yes" \
        -p "PrivateTmp=yes" \
        -p "PrivateDevices=yes" \
        -p "ProtectSystem=strict" \
        -p "ProtectHome=yes" \
        -p "Environment=HOME=$GMI_DIR" \
        -p "Environment=XDG_DATA_HOME=$GMI_DIR" \
        -p "BindReadOnlyPaths=$HOME/.notmuch-config:$GMI_DIR/.notmuch-config" \
        -p "ReadWritePaths=$GMI_DIR" \
        -p "WorkingDirectory=$GMI_DIR" \
        -p "UMask=0077" \
        -p "RestrictSUIDSGID=yes" \
        -p "CapabilityBoundingSet=" \
        -p "LockPersonality=yes" \
        -p "MemoryDenyWriteExecute=yes" \
        -p "RestrictNamespaces=yes" \
        -p "RestrictRealtime=yes" \
        -p "ProtectKernelTunables=yes" \
        -p "ProtectControlGroups=yes" \
        -p "ProtectClock=yes" \
        -p "ProtectHostname=yes" \
        -p "RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6" \
        -p "ProtectProc=invisible" \
        -p "ProcSubset=pid" \
        -- notmuch search "$@"
}
#DANGER_NETWORK_mail_file="$(notmuch search --output=files --sort=newest-first \
#  "from:$other_email_address subject:\"DH Point Update\"" | head -n 1)"