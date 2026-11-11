#!/usr/bin/env bash
set -euo pipefail

if [[ $(dpkg --print-architecture) != amd64 ]]; then
    printf 'This Steam setup requires amd64.\n' >&2
    exit 1
fi

if ! dpkg --print-foreign-architectures | grep -Fxq i386; then
    sudo dpkg --add-architecture i386
fi
package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# Recheck coverage after enabling i386, including on repeat installs.
python3 "$package_dir/../debian-apt/sources.py"
sudo apt-get update
sudo apt-get install -y --no-remove -- steam-installer libgl1-mesa-dri:i386 libglx-mesa0:i386
