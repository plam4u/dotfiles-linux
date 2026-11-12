#!/usr/bin/env bash
set -euo pipefail

. /etc/os-release
[[ $ID == omarchy ]] || exit 0

input="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/input.lua"
if [[ -L $input || ! -f $input ]]; then
    printf 'Expected a regular Omarchy input configuration: %s\n' "$input" >&2
    exit 1
fi
setting='hl.config({ input = { kb_layout = "us", kb_variant = "altgr-intl" } })'
if ! grep -Fxq -- "$setting" "$input"; then
    staged=$(mktemp -- "${input%/*}/.pm-input.XXXXXX")
    trap 'rm -f -- "$staged"' EXIT
    cp -p -- "$input" "$staged"
    printf '\n-- Keyboard layout managed by dotfiles-linux system-preferences.\n%s\n' "$setting" >> "$staged"
    mv -vT --backup=numbered -- "$staged" "$input"
fi
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl reload
    errors=$(hyprctl configerrors)
    if [[ -n $errors ]]; then
        printf 'Hyprland configuration errors:\n%s\n' "$errors" >&2
        exit 1
    fi
else
    printf 'Hyprland will load the keyboard layout at next login.\n'
fi
