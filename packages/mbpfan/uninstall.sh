#!/usr/bin/env bash
set -euo pipefail

if systemctl cat mbpfan.service >/dev/null 2>&1; then
    sudo systemctl disable --now mbpfan.service
fi

. /etc/os-release
if [[ $ID == arch || $ID == omarchy ]]; then
    package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
    . "$package_dir/../../share/uninstall.sh"
    remove_native_packages mbpfan
fi
