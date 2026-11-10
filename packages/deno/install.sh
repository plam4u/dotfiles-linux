#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/install.sh"

deno="$HOME/.deno/bin/deno"
work_dir=$(mktemp -d)
trap 'rm -r -- "$work_dir"' EXIT

if [[ -x $deno && -f $deno ]]; then
    printf '  Already installed: %s\n' "$deno"
else
    if [[ -e $deno || -L $deno ]]; then
        printf 'Review the existing file at %s before retrying.\n' "$deno" >&2
        exit 1
    fi
    if [[ $(uname -m) != x86_64 ]]; then
        printf 'The pinned Deno archive requires x86-64.\n' >&2
        exit 1
    fi
    if ! download_verified \
        https://github.com/denoland/deno/releases/download/v2.9.8/deno-x86_64-unknown-linux-gnu.zip \
        e890975bc2549807bbcc0b584ffafda72cc7c93349dd99c80483dd784f6c4609 "$work_dir/deno.zip"; then
        printf 'Could not download or verify Deno 2.9.8.\n' >&2
        exit 1
    fi
    unzip -p "$work_dir/deno.zip" deno > "$work_dir/deno"
    install -D -m 0755 -- "$work_dir/deno" "$deno"
fi

write_completion() {
    local shell=$1 destination=$2
    if [[ ! -e $destination && ! -L $destination ]]; then
        "$deno" completions "$shell" > "$work_dir/$shell"
        install -D -m 0644 -- "$work_dir/$shell" "$destination"
    fi
}

write_completion bash "$HOME/.local/share/bash-completion/completions/deno.bash"
write_completion zsh "$HOME/.zsh/completions/_deno"
