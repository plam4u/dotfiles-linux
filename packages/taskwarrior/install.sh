#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/install.sh"

version=3.5.0
prefix="$HOME/.local/opt/taskwarrior-$version"
link="$HOME/.local/bin/task"

if [[ -e $link || -L $link ]] && [[ $(readlink -- "$link") != "$prefix/bin/task" ]]; then
    printf 'Review the existing path at %s before retrying.\n' "$link" >&2
    exit 1
fi

if [[ ! -x $prefix/bin/task ]]; then
    mkdir -p -- "$HOME/.local/opt"
    work_dir=$(mktemp -d "$HOME/.local/opt/.taskwarrior-build.XXXXXX")
    trap 'rm -rf -- "$work_dir"' EXIT
    cd -- "$work_dir"

    download_verified \
        "https://github.com/GothenburgBitFactory/taskwarrior/releases/download/v$version/task-$version.tar.gz" \
        9ea64b411f8314414f440ec765dfdf5a86c9f6159df47e2f60cff3db6b31157a \
        "task-$version.tar.gz"
    tar -xzf "task-$version.tar.gz"

    # Extract Debian's Rustup package to avoid conflicts with system Rust packages.
    apt-get download rustup
    dpkg-deb -x rustup_*.deb "$work_dir/rustup"
    export RUSTUP_HOME="$work_dir/rustup-home" CARGO_HOME="$work_dir/cargo-home"
    rustup="$work_dir/rustup/usr/bin/rustup"
    toolchain=1.96.1
    "$rustup" toolchain install "$toolchain" --profile minimal
    cargo=$("$rustup" which --toolchain "$toolchain" cargo)
    export PATH="${cargo%/*}:$PATH"

    cd -- "task-$version"
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix"
    cmake --build build --parallel 2
    DESTDIR="$work_dir/install" cmake --install build
    staged="$work_dir/install$prefix"
    [[ $("$staged/bin/task" --version) == "$version" ]]
    mv -T -- "$staged" "$prefix"
fi

mkdir -p -- "$HOME/.local/bin"
if [[ ! -L $link ]]; then
    ln -s -- "$prefix/bin/task" "$link"
fi
