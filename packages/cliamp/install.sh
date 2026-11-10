#!/usr/bin/env bash
set -euo pipefail

if [[ -x /usr/local/bin/cliamp ]]; then
    printf '  Already installed: /usr/local/bin/cliamp\n'
    exit 0
fi
if [[ $(uname -m) != x86_64 ]]; then
    printf 'The pinned CLIamp binary requires x86-64.\n' >&2
    exit 1
fi

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/install.sh"
install_user_binary cliamp \
    https://github.com/bjarneo/cliamp/releases/download/v2.4.0/cliamp-linux-amd64 \
    2ee17d8f613d9dd23d124b8f5580111610f5aa396b20f2818e388f7b7a227152
