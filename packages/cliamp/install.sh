#!/usr/bin/env bash
set -euo pipefail

if [[ -x /usr/local/bin/cliamp ]]; then
    printf '  Already installed: /usr/local/bin/cliamp\n'
    exit 0
fi
architecture=$(uname -m)
case $architecture in
    x86_64)
        asset=cliamp-linux-amd64
        digest=2ee17d8f613d9dd23d124b8f5580111610f5aa396b20f2818e388f7b7a227152
        ;;
    aarch64)
        asset=cliamp-linux-arm64
        digest=4e686e9b5188030bd3382c7fac997077bbdff8953fbab0003c49874b5f9ea1fc
        ;;
    *) printf 'No pinned CLIamp binary for %s.\n' "$architecture" >&2; exit 1 ;;
esac

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/install.sh"
install_user_binary cliamp \
    "https://github.com/bjarneo/cliamp/releases/download/v2.4.0/$asset" "$digest"
