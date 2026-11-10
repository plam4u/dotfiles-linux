#!/usr/bin/env bash
set -euo pipefail

if [[ $(dpkg-query -W -f='${Status}' -- obsidian 2>/dev/null) == 'install ok installed' ]]; then
    printf '  Already installed: obsidian\n'
    exit 0
fi
if [[ $(dpkg --print-architecture) != amd64 ]]; then
    printf 'The pinned Obsidian installer requires amd64.\n' >&2
    exit 1
fi

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/debian-install.sh"
work_dir=$(mktemp -d)
trap 'rm -r -- "$work_dir"' EXIT
version=1.15.0
name="obsidian_${version}_amd64.deb"
download_verified "https://github.com/obsidianmd/obsidian-releases/releases/download/v$version/$name" \
    251805fdcb696af32129e8f5e8656f6688802fc38b169822175d23a74c5174b3 "$work_dir/$name"
chmod 0755 "$work_dir"
sudo apt-get update
sudo apt-get install -y --no-remove -- "$work_dir/$name"
