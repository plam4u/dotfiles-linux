#!/usr/bin/env bash
set -euo pipefail

# Yubico Authenticator uses the same smart-card socket.
if command -v flatpak >/dev/null &&
    flatpak info com.yubico.yubioath >/dev/null 2>&1; then
    exit 0
fi

if systemctl cat pcscd.socket >/dev/null 2>&1; then
    sudo systemctl disable --now pcscd.socket
    sudo systemctl stop pcscd.service
fi
