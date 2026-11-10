#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$package_dir/../../share/install.sh"
install_user_binary yt-dlp https://github.com/yt-dlp/yt-dlp/releases/download/2026.10.26/yt-dlp \
    e51e69e89489f199530f13d32a4342da3ddb2cf34842f364603a066db05afbf3
