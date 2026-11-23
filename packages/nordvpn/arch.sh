#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
if ! pacman -Q -- nordvpn-bin >/dev/null 2>&1; then
    work_dir=$(mktemp -d)
    trap 'rm -rf -- "$work_dir"' EXIT
    cp -- "$package_dir/arch/PKGBUILD" "$work_dir/"
    (
        cd -- "$work_dir"
        makepkg --syncdeps --noconfirm
        mapfile -t archives < <(makepkg --packagelist)
        sudo pacman -U --needed --noconfirm -- "${archives[@]}"
    )
fi
bash "$package_dir/activate.sh"
