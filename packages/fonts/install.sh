#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$package_dir/../../share/install.sh"

font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT
mkdir -- "$work_dir/JetBrainsMono" "$work_dir/MesloLGS" "$work_dir/MesloLGSNerdFontMono"

jetbrains_url=https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz
jetbrains_sha=04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf
meslo_nerd_url=https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/Meslo.tar.xz
meslo_nerd_sha=6b6624632dc6873dfb7681c3f818e7c01ab601ab707690b6440933bbe57e2b11
meslo_url=https://raw.githubusercontent.com/romkatv/powerlevel10k-media/145eb9fbc2f42ee408dacd9b22d8e6e0e553f83d

download_verified "$jetbrains_url" "$jetbrains_sha" "$work_dir/JetBrainsMono.tar.xz"
tar -xJf "$work_dir/JetBrainsMono.tar.xz" -C "$work_dir/JetBrainsMono" --wildcards '*.ttf'

download_verified "$meslo_nerd_url" "$meslo_nerd_sha" "$work_dir/Meslo.tar.xz"
tar -xJf "$work_dir/Meslo.tar.xz" -C "$work_dir/MesloLGSNerdFontMono" --wildcards 'MesloLGSNerdFontMono-*.ttf'

while read -r style digest; do
    filename="MesloLGS%20NF%20$style.ttf"
    download_verified "$meslo_url/$filename" "$digest" "$work_dir/MesloLGS/$filename"
done <<'FONTS'
Regular d97946186e97f8d7c0139e8983abf40a1d2d086924f2c5dbf1c29bd8f2c6e57d
Bold b6c0199cf7c7483c8343ea020658925e6de0aeb318b89908152fcb4d19226003
Italic 6f357bcbe2597704e157a915625928bca38364a89c22a4ac36e7a116dcd392ef
FONTS

missing=()
for font in "$work_dir"/{JetBrainsMono,MesloLGS,MesloLGSNerdFontMono}/*.ttf; do
    destination="$font_dir/${font#"$work_dir/"}"
    if [[ -L $destination || -e $destination ]]; then
        if [[ -L $destination || ! -f $destination ]] || ! cmp -s -- "$font" "$destination"; then
            printf 'Review the existing font before retrying: %s\n' "$destination" >&2
            exit 1
        fi
    else
        missing+=("$font")
    fi
done

for font in "${missing[@]}"; do
    install -vD -m 0644 -- "$font" "$font_dir/${font#"$work_dir/"}"
done
fc-cache -f -- "$font_dir"
printf 'JetBrains Mono Nerd Font, MesloLGS NF, and MesloLGS Nerd Font Mono are available in %s.\n' "$font_dir"
