#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/uninstall.sh"

remove_matching_file "$package_dir/defaults/keyd.conf" /etc/keyd/default.conf

config=/etc/modprobe.d/imac2011-keyboard.conf
if [[ ! -L $config && -f $config ]] &&
    cmp -s -- "$package_dir/defaults/imac2011-keyboard.conf" "$config"; then
    sudo rm -v -- "$config"
    sudo /usr/sbin/update-initramfs -u
    printf 'Reboot to load the remaining Apple keyboard settings.\n'
elif [[ -e $config || -L $config ]]; then
    printf 'Keeping changed file: %s\n' "$config" >&2
fi
