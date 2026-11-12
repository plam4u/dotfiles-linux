#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/uninstall.sh"
remove_matching_file "$package_dir/zz-imac2011-keyboard.conf" /etc/modprobe.d/zz-imac2011-keyboard.conf
sudo /usr/sbin/update-initramfs -u
printf 'Reboot to load the remaining Apple keyboard settings.\n'
