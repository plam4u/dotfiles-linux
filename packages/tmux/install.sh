#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
if tmux -N has-session 2>/dev/null; then
    tmux source-file "$package_dir/stow/.tmux.conf"
    printf 'Reloaded the running tmux server configuration.\n'
fi
