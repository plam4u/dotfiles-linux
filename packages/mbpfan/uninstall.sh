#!/usr/bin/env bash
set -euo pipefail

if systemctl cat mbpfan.service >/dev/null 2>&1; then
    sudo systemctl disable --now mbpfan.service
fi
