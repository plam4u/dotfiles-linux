#!/usr/bin/env bash
set -euo pipefail

prefix=/opt/vim82
link=/usr/local/bin/vim82
if [[ -L $link && $(readlink -- "$link") == "$prefix/bin/vim" ]]; then
    sudo rm -v -- "$link"
elif [[ -e $link || -L $link ]]; then
    printf 'Keeping unrelated Vim binary: %s\n' "$link"
fi
sudo rm -rfv -- "$prefix"
