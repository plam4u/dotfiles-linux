#!/usr/bin/env bash
set -euo pipefail

if [[ $(uname -s) == Darwin ]]; then
    if ! command -v brew >/dev/null; then
        printf 'Install Homebrew from https://brew.sh, then run this script again.\n' >&2
        exit 1
    fi
    if brew list --cask chatgpt >/dev/null 2>&1; then
        printf 'Already installed: ChatGPT\n'
        exit 0
    fi
    exec brew install --cask chatgpt
fi

. /etc/os-release
if [[ $ID == arch ]]; then
    if pacman -Q chatgpt >/dev/null 2>&1; then
        printf 'Already installed: ChatGPT\n'
        exit 0
    fi
    if ! command -v curl >/dev/null; then
        sudo pacman -S --needed curl
    fi
    work_dir=$(mktemp -d)
    trap 'rm -r -- "$work_dir"' EXIT
    curl --proto '=https' --tlsv1.2 -fL \
        https://persistent.oaistatic.com/codex-app-prod/linux/install-arch.sh \
        -o "$work_dir/install-arch.sh"
    printf 'The official ChatGPT installer configures its signed repository and prompts for a full Arch system upgrade.\n'
    sudo bash "$work_dir/install-arch.sh"
    exit
fi

architecture=$(dpkg --print-architecture)
case $architecture in
    amd64|arm64) ;;
    *) printf 'The ChatGPT APT source has no build for %s.\n' "$architecture" >&2; exit 1 ;;
esac

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/install.sh"
work_dir=$(mktemp -d)
trap 'rm -r -- "$work_dir"' EXIT
sed "s/@ARCH@/$architecture/" "$package_dir/defaults/chatgpt.sources" > "$work_dir/chatgpt.sources"
cp -- "$package_dir/defaults/chatgpt-archive-keyring.gpg" "$work_dir/"
install_vendor_package chatgpt "$work_dir" chatgpt.sources
