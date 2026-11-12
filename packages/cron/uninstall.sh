#!/usr/bin/env bash
set -euo pipefail

. /etc/os-release
service=cron.service
[[ $ID != arch && $ID != omarchy ]] || service=cronie.service
if systemctl cat "$service" >/dev/null 2>&1; then
    sudo systemctl disable --now "$service"
fi
