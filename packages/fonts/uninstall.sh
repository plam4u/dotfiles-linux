#!/usr/bin/env bash
set -euo pipefail

font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
shopt -s nullglob
fonts=("$font_dir"/JetBrainsMono/JetBrainsMono*.ttf
    "$font_dir/MesloLGS/MesloLGS%20NF%20Regular.ttf"
    "$font_dir/MesloLGS/MesloLGS%20NF%20Bold.ttf"
    "$font_dir/MesloLGS/MesloLGS%20NF%20Italic.ttf")
rm -fv -- "${fonts[@]}"
if [[ -d $font_dir ]] && command -v fc-cache >/dev/null; then
    fc-cache -f -- "$font_dir"
fi
