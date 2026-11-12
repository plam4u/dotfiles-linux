#!/usr/bin/env bash
set -euo pipefail

service=keyd.service
sudo systemctl enable --now "$service"
