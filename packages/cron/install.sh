#!/usr/bin/env bash
set -euo pipefail

. /etc/os-release
service=cron.service
[[ $ID != arch && $ID != omarchy ]] || service=cronie.service
sudo systemctl enable --now "$service"
