#!/usr/bin/env bash
set -euo pipefail

service=NetworkManager.service
if systemctl cat "$service" >/dev/null 2>&1; then
    sudo systemctl disable --now "$service"
fi
