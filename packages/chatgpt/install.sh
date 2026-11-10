#!/usr/bin/env bash
set -euo pipefail

if [[ $(dpkg --print-architecture) != amd64 ]]; then
    printf 'The configured ChatGPT APT source requires amd64.\n' >&2
    exit 1
fi
package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/debian-install.sh"
install_vendor_package chatgpt "$package_dir/defaults" chatgpt.sources
