#!/usr/bin/env bash
set -euo pipefail

if systemctl cat lightdm.service >/dev/null 2>&1; then
    sudo systemctl disable --now lightdm.service
fi
