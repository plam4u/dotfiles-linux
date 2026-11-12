#!/usr/bin/env bash
set -euo pipefail

sudo systemctl reset-failed mbpfan.service
sudo systemctl enable mbpfan.service
sudo systemctl restart mbpfan.service
