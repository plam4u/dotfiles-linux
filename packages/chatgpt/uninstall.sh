#!/usr/bin/env bash
set -euo pipefail

if [[ $(uname -s) == Darwin ]]; then
    exec brew uninstall --cask chatgpt
fi

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/uninstall.sh"
. /etc/os-release
if [[ $ID == arch || $ID == omarchy ]]; then
    remove_native_packages chatgpt
    printf 'The repository configured by the upstream ChatGPT installer is left in place.\n'
else
    work_dir=$(mktemp -d)
    trap 'rm -r -- "$work_dir"' EXIT
    sed "s/@ARCH@/$(dpkg --print-architecture)/" "$package_dir/defaults/chatgpt.sources" > "$work_dir/chatgpt.sources"
    cp -- "$package_dir/defaults/chatgpt-archive-keyring.gpg" "$work_dir/"
    remove_vendor_package chatgpt "$work_dir" chatgpt.sources
fi
