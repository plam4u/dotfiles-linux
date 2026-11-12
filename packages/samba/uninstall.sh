#!/usr/bin/env bash
set -euo pipefail

. /etc/os-release
service=smbd.service
[[ $ID != arch && $ID != omarchy ]] || service=smb.service
if systemctl cat "$service" >/dev/null 2>&1; then
    sudo systemctl disable --now "$service"
fi
printf 'Keeping Samba configuration, accounts, and shared files.\n'
