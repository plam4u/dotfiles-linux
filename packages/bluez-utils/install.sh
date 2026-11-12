#!/usr/bin/env bash
set -euo pipefail

service=bluetooth.service
sudo systemctl enable --now "$service"
