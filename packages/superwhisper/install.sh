#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/install.sh"
architecture=$(uname -m)
case $architecture in
    x86_64) digest=464a732ca6c928d3f2b8bb94687176a75ca2b09c186333d34d94d051ccb5f0e4 ;;
    aarch64) digest=a440c85ea31bdb0c3c3b3de971a042402cc698efa27c54dc573c9553fd28f06f ;;
    *) printf 'Unsupported architecture: %s\n' "$architecture" >&2; exit 1 ;;
esac
work_dir=$(mktemp -d)
trap 'rm -r -- "$work_dir"' EXIT
archive="superwhisper-omarchy-$architecture-1.3.1"
download_verified "https://tux.superwhisper.com/$architecture/v1.3.1/$archive.tar.zst" \
    "$digest" "$work_dir/release.tar.zst"
tar --zstd -xf "$work_dir/release.tar.zst" -C "$work_dir"
# The vendor installer installs runtime dependencies and enables the user service.
bash "$work_dir/$archive/install.sh"
