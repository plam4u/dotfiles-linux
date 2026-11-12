#!/usr/bin/env bash
set -euo pipefail

. /etc/os-release
service=ssh.service
[[ $ID != arch && $ID != omarchy ]] || service=sshd.service
sudo systemctl enable --now "$service"
