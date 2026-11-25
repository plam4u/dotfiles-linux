#!/usr/bin/env bash
set -euo pipefail

if systemctl cat pcscd.socket >/dev/null 2>&1; then
    sudo systemctl disable --now pcscd.socket
    sudo systemctl stop pcscd.service
fi
