#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/uninstall.sh"
remove_matching_file "$package_dir/default.conf" /etc/keyd/default.conf
