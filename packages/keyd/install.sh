#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config=/etc/keyd/default.conf
if [[ -L $config || ( -e $config && ! -f $config ) ]]; then
    printf 'Review the existing keyd config path: %s\n' "$config" >&2
    exit 1
fi

sudo install -vCT --backup=numbered -o root -g root -m 0644 -- \
    "$package_dir/default.conf" "$config"
if systemctl is-active --quiet keyd.service; then
    sudo keyd reload
fi
