#!/usr/bin/env bash
set -euo pipefail

service=bluetooth.service
if systemctl cat "$service" >/dev/null 2>&1; then
    sudo systemctl disable --now "$service"
fi
