#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/uninstall.sh"

if systemctl cat nordvpnd.socket >/dev/null 2>&1; then
    sudo systemctl disable --now nordvpnd.service nordvpnd.socket
    sudo systemctl stop nordvpnd-killswitch.service
fi

. /etc/os-release
case $ID in
    debian)
        remove_vendor_package nordvpn "$package_dir/defaults" nordvpn-release.sources
        ;;
    arch|omarchy)
        remove_native_packages nordvpn-bin
        ;;
esac
