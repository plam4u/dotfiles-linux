#!/usr/bin/env bash
set -euo pipefail

if systemctl cat logrotate.timer >/dev/null 2>&1; then
    sudo systemctl disable --now logrotate.timer
fi
