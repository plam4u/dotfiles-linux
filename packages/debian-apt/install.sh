#!/usr/bin/env bash
set -euo pipefail

. /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'This APT setup requires Debian 13 (trixie).\n' >&2
    exit 1
fi

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
exec python3 "$package_dir/sources.py" "$@"
