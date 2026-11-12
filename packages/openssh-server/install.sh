#!/usr/bin/env bash
set -euo pipefail

. /etc/os-release
service=ssh.service
[[ $ID != arch ]] || service=sshd.service
sudo systemctl enable --now "$service"
