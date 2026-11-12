#!/usr/bin/env bash
set -euo pipefail

prefix="$HOME/.local/opt/neovim-c868e1ab3d11ac2a0cc3c284b16808f3de5adf31"
link="$HOME/.local/bin/nvim"
if [[ -L $link && $(readlink -- "$link") == "$prefix/bin/nvim" ]]; then
    rm -v -- "$link"
elif [[ -e $link || -L $link ]]; then
    printf 'Keeping unrelated Neovim binary: %s\n' "$link"
fi
rm -rfv -- "$prefix"
