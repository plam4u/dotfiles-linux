#!/usr/bin/env bash
set -euo pipefail

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
terminal_dir="$config_home/xfce4/terminal"
channel_file="$config_home/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml"

for path in "$terminal_dir/accels.scm" "$terminal_dir/terminalrc" "$channel_file"; do
    if [[ -L $path || ( -e $path && ! -f $path ) ]]; then
        printf 'Review the existing path at %s before retrying.\n' "$path" >&2
        exit 1
    fi
done

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

mkdir -p -- "$terminal_dir"
for name in accels.scm terminalrc; do
    if ! cmp -s "$package_dir/defaults/$name" "$terminal_dir/$name"; then
        cp -pv --backup=numbered -- "$package_dir/defaults/$name" "$terminal_dir/$name"
    fi
done
