#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT

config=$(< "$package_dir/defaults/smb.conf")
config=${config//@HOME@/"$HOME"}
config=${config//@USER@/"$(id -un)"}
printf '%s\n' "$config" > "$work_dir/smb.conf"
testparm -s "$work_dir/smb.conf" >/dev/null

destination=/etc/samba/smb.conf
if [[ -L $destination || ( -e $destination && ! -f $destination ) ]]; then
    printf 'Review the existing Samba config path: %s\n' "$destination" >&2
    exit 1
fi
mkdir -p -- "$HOME/Public"
sudo install -vDCT --backup=numbered -o root -g root -m 0644 -- \
    "$work_dir/smb.conf" "$destination"
. /etc/os-release
service=smbd.service
[[ $ID != arch ]] || service=smb.service
user=$(id -un)
if ! sudo pdbedit -L -u "$user" | cut -d: -f1 | grep -Fx "$user" >/dev/null; then
    sudo smbpasswd -a "$user"
fi
sudo systemctl enable --now "$service"
sudo systemctl reload "$service"
