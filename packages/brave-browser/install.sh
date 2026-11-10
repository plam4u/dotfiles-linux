#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/debian-install.sh"
install_vendor_package brave-browser "$package_dir/defaults" brave-browser-release.sources
