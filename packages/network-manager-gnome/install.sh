#!/usr/bin/env bash
set -euo pipefail

service=NetworkManager.service
sudo systemctl enable --now "$service"
