#!/usr/bin/env bash
set -euo pipefail

for service in docker.service docker.socket; do
    if systemctl cat "$service" >/dev/null 2>&1; then
        sudo systemctl disable --now "$service"
    fi
done
. /etc/os-release
[[ $ID == debian ]] || exit 0

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/uninstall.sh"
remove_native_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

work_dir=$(mktemp -d)
trap 'rm -r -- "$work_dir"' EXIT
sed "s/@ARCH@/$(dpkg --print-architecture)/" \
    "$package_dir/defaults/debian/trixie/docker.sources" > "$work_dir/docker.sources"
remove_matching_file "$work_dir/docker.sources" /etc/apt/sources.list.d/docker.sources
printf 'Docker data and /etc/apt/keyrings/docker.asc are left in place.\n'
