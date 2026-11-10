#!/usr/bin/env bash
set -euo pipefail

. /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Docker package requires Debian 13 (trixie).\n' >&2
    exit 1
fi

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
work_dir=$(mktemp -d)
trap 'rm -r -- "$work_dir"' EXIT

source_path=/etc/apt/sources.list.d/docker.sources
key_path=/etc/apt/keyrings/docker.asc
sed "s/@ARCH@/$(dpkg --print-architecture)/" \
    "$package_dir/defaults/debian/trixie/docker.sources" > "$work_dir/docker.sources"

if [[ -e $source_path || -L $source_path ]] && ! cmp -s "$work_dir/docker.sources" "$source_path"; then
    printf 'Docker package found a different APT source at %s. Review it before retrying.\n' "$source_path" >&2
    exit 1
fi

if [[ ! -s $key_path ]]; then
    if ! command -v curl >/dev/null || [[ ! -s /etc/ssl/certs/ca-certificates.crt ]]; then
        sudo apt-get update
        sudo apt-get install -y --no-remove ca-certificates curl
    fi
    curl --fail --silent --show-error --location --proto '=https' \
        https://download.docker.com/linux/debian/gpg --output "$work_dir/docker.asc"
    sudo install -d -m 0755 /etc/apt/keyrings
    sudo install -m 0644 "$work_dir/docker.asc" "$key_path"
fi

if [[ ! -e $source_path ]]; then
    sudo install -m 0644 "$work_dir/docker.sources" "$source_path"
fi
sudo apt-get update
sudo apt-get install -y --no-remove \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
