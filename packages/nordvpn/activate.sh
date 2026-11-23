#!/usr/bin/env bash
set -euo pipefail

user=$(id -un)
if [[ " $(id -nG "$user") " != *' nordvpn '* ]]; then
    sudo usermod -aG nordvpn "$user"
fi

sudo systemctl daemon-reload
sudo systemctl enable --now nordvpnd.socket
if [[ " $(id -nG) " != *' nordvpn '* ]]; then
    printf '  Log out and back in to apply NordVPN group membership.\n'
fi
printf '  Run nordvpn login to sign in, then nordvpn connect.\n'
