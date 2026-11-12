#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
installed_version=$(pacman -Q mbpfan 2>/dev/null | cut -d ' ' -f2) || installed_version=
if [[ -z $installed_version ]] || (( $(vercmp "$installed_version" 2.4.0-2) < 0 )); then
    work_dir=$(mktemp -d)
    trap 'rm -rf -- "$work_dir"' EXIT
    cp -- "$package_dir/arch/"* "$work_dir/"
    (
        cd -- "$work_dir"
        makepkg --noconfirm
        mapfile -t archives < <(makepkg --packagelist)
        sudo pacman -U --needed --noconfirm -- "${archives[@]}"
    )
fi
sudo modprobe applesmc
sudo modprobe coretemp
sudo systemctl daemon-reload
