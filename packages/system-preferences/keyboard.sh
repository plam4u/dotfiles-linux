#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

install_config() {
    local source=$1 destination=$2
    if [[ -L $destination || ( -e $destination && ! -f $destination ) ]]; then
        printf 'Review the existing config path: %s\n' "$destination" >&2
        exit 1
    fi
    sudo install -vDCT --backup=numbered -o root -g root -m 0644 -- "$source" "$destination"
}

install_config "$package_dir/defaults/keyd.conf" /etc/keyd/default.conf
sudo systemctl enable --now keyd.service
keyd_command=$(command -v keyd.rvaiya || command -v keyd)
sudo "$keyd_command" reload

# Apple driver preferences apply only to the supported iMac.
. /etc/os-release
model=
if [[ -r /sys/devices/virtual/dmi/id/product_name ]]; then
    read -r model < /sys/devices/virtual/dmi/id/product_name
fi
if [[ $(uname -m) == x86_64 && $model == iMac12,2 ]]; then
    config=/etc/modprobe.d/imac2011-keyboard.conf
    if ! cmp -s -- "$package_dir/defaults/imac2011-keyboard.conf" "$config"; then
        install_config "$package_dir/defaults/imac2011-keyboard.conf" "$config"
        . "$package_dir/share/initramfs.sh"
        rebuild_initramfs
        printf 'Reboot to load the Apple keyboard settings.\n'
    fi
fi
