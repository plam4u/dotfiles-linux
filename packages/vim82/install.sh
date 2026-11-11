#!/usr/bin/env bash
set -euo pipefail

prefix=/opt/vim82
binary="$prefix/bin/vim"
link=/usr/local/bin/vim82

if [[ -e $link || -L $link ]] && [[ $(readlink -- "$link") != "$binary" ]]; then
  printf 'Review the existing path at %s before retrying.\n' "$link" >&2
  exit 1
fi

work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT
git clone --depth 1 --branch v8.2.5172 https://github.com/vim/vim.git "$work_dir/vim"
cd -- "$work_dir/vim"
# Keep Vim 8.2 on GNU C17 even when the compiler defaults to C23.
CFLAGS="${CFLAGS:--O2} -std=gnu17" ./configure \
  --prefix="$prefix" \
  --with-features=huge \
  --enable-multibyte \
  --enable-terminal \
  --enable-cscope
make -j"$(nproc)"
sudo make install
if [[ $(readlink -- "$link") != "$binary" ]]; then
  sudo ln -sT -- "$binary" "$link"
fi
