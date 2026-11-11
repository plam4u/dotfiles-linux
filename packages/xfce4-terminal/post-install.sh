#!/usr/bin/env bash
set -euo pipefail

if [[ ${XDG_CONFIG_HOME:-$HOME/.config} != "$HOME/.config" ]]; then
    printf 'This restore requires XDG_CONFIG_HOME to be unset or equal to ~/.config.\n' >&2
    exit 1
fi

if pgrep -x -u "$UID" xfce4-terminal >/dev/null; then
    printf 'Close XFCE Terminal and run this from another terminal in the same desktop session.\n' >&2
    exit 1
fi
if ! xfconf-query --list >/dev/null; then
    printf 'Run this script with access to your user D-Bus session.\n' >&2
    exit 1
fi

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
channel_file="$config_home/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml"

if [[ -L $channel_file || ( -e $channel_file && ! -f $channel_file ) ]]; then
    printf 'Review the existing path at %s before retrying.\n' "$channel_file" >&2
    exit 1
fi
"$package_dir/../../bin/pm" stow xfce4-terminal

backed_up=0
while IFS=$'\t' read -r property type value; do
    [[ -n $property && $property != \#* ]] || continue
    args=(--channel xfce4-terminal --property "/$property")
    if current=$(xfconf-query "${args[@]}" 2>/dev/null) && [[ $current == "$value" ]]; then
        continue
    fi
    if (( ! backed_up )) && [[ -f $channel_file ]]; then
        cp -pv --backup=numbered -- "$channel_file" "$channel_file.bak"
        backed_up=1
    fi
    xfconf-query "${args[@]}" --create --type "$type" --set "$value"
    printf 'Set XFCE Terminal property /%s\n' "$property"
done < "$package_dir/defaults/xfconf.tsv"
