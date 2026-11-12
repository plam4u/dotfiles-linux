#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/uninstall.sh"

if systemctl cat keyd.service >/dev/null 2>&1; then
    sudo systemctl disable --now keyd.service
fi
remove_matching_file "$package_dir/defaults/keyd.conf" /etc/keyd/default.conf

config=/etc/modprobe.d/imac2011-keyboard.conf
if [[ ! -L $config && -f $config ]] &&
    cmp -s -- "$package_dir/defaults/imac2011-keyboard.conf" "$config"; then
    sudo rm -v -- "$config"
    . "$package_dir/share/initramfs.sh"
    rebuild_initramfs
    printf 'Reboot to load the remaining Apple keyboard settings.\n'
elif [[ -e $config || -L $config ]]; then
    printf 'Keeping changed file: %s\n' "$config" >&2
fi
