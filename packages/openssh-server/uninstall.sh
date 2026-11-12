#!/usr/bin/env bash
set -euo pipefail

. /etc/os-release
service=ssh.service
[[ $ID != arch ]] || service=sshd.service
if systemctl cat "$service" >/dev/null 2>&1; then
    sudo systemctl disable --now "$service"
fi
