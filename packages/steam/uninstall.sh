#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/uninstall.sh"
remove_native_packages steam-installer libgl1-mesa-dri:i386 libglx-mesa0:i386
printf 'Steam libraries, the i386 architecture, and shared Debian sources are left in place.\n'
