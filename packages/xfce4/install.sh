#!/usr/bin/env bash
set -euo pipefail

# Enable graphical login at boot so the offline restore can finish before sign-in.
sudo systemctl enable lightdm.service
sudo systemctl set-default graphical.target
printf 'Graphical login is enabled for the next boot. Complete the desktop restore before signing in.\n'
