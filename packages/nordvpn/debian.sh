#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/install.sh"

# APT needs this before it can fetch the HTTPS repository. Keep the system
# trust store out of pm's package removal plan.
if [[ $(dpkg-query -W -f='${db:Status-Status}' -- ca-certificates 2>/dev/null) != installed ]]; then
    sudo apt-get update
    sudo apt-get install -y --no-remove -- ca-certificates
fi

install_vendor_package nordvpn "$package_dir/defaults" nordvpn-release.sources
bash "$package_dir/activate.sh"
