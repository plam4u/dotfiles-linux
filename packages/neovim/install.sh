#!/usr/bin/env bash
set -euo pipefail

if [[ -x "$HOME/.local/bin/nvim" || -x /usr/local/bin/nvim ]]; then
    printf '  Already installed: Neovim\n'
    exit 0
fi

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/debian-install.sh"
commit=c868e1ab3d11ac2a0cc3c284b16808f3de5adf31
prefix="$HOME/.local/opt/neovim-$commit"
link="$HOME/.local/bin/nvim"
if [[ -e $link || -L $link ]]; then
    printf 'Review the existing path at %s before retrying.\n' "$link" >&2
    exit 1
fi

if [[ ! -x $prefix/bin/nvim ]]; then
    mkdir -p -- "$HOME/.local/opt"
    work_dir=$(mktemp -d "$HOME/.local/opt/.neovim-build.XXXXXX")
    trap 'rm -r -- "$work_dir"' EXIT
    if [[ $(dpkg --print-architecture) == amd64 ]] && download_verified \
        https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz \
        25b78146d4d8772e47a07b101f76c14e1ac77e60dd09b455883a0deccc370978 \
        "$work_dir/nvim.tar.gz"; then
        tar -xzf "$work_dir/nvim.tar.gz" -C "$work_dir"
        staged="$work_dir/nvim-linux-x86_64"
    else
        printf 'Building the recorded Neovim commit %s.\n' "$commit"
        git init -q "$work_dir/source"
        git -C "$work_dir/source" fetch --depth=1 https://github.com/neovim/neovim.git "$commit"
        git -C "$work_dir/source" checkout -q --detach "$commit"
        make -C "$work_dir/source" CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$prefix"
        DESTDIR="$work_dir/install" cmake --install "$work_dir/source/build"
        staged="$work_dir/install$prefix"
    fi
    test -x "$staged/bin/nvim"
    mv -T -- "$staged" "$prefix"
fi

mkdir -p -- "$HOME/.local/bin"
ln -s -- "$prefix/bin/nvim" "$link"
