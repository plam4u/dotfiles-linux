#!/usr/bin/env bash
set -euo pipefail

source_path=/etc/apt/sources.list.d/pm-debian.sources
if [[ ! -e $source_path && ! -L $source_path ]]; then
    exit 0
fi
if [[ -L $source_path ]] || [[ $(head -n 1 -- "$source_path") != '# Managed by pm (debian-apt)' ]]; then
    printf 'Keeping unmanaged APT source: %s\n' "$source_path" >&2
    exit 0
fi
sudo rm -v -- "$source_path"
printf 'Removed the pm Debian source entries; existing sources and backups are unchanged.\n'
