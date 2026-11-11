#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config=zz-imac2011-keyboard.conf

sudo install -vCT --backup=numbered -o root -g root -m 0644 -- \
    "$package_dir/$config" "/etc/modprobe.d/$config"
sudo /usr/sbin/update-initramfs -u
printf 'Reboot to load the Apple keyboard settings.\n'
