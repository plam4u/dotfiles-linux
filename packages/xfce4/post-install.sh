#!/usr/bin/env bash
set -euo pipefail

if [[ ${XDG_CONFIG_HOME:-$HOME/.config} != "$HOME/.config" ]]; then
    printf 'This restore requires XDG_CONFIG_HOME to be unset or equal to ~/.config.\n' >&2
    exit 1
fi

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_dir=${XDG_CONFIG_HOME:-$HOME/.config}
packages=(xfce4)
dry_run=0
check_session=0

for arg in "$@"; do
    case $arg in
        --dry-run) dry_run=1 ;;
        --check-session) check_session=1 ;;
        --imac2011) packages=(xfce4 xfce4-imac2011) ;;
        -h|--help)
            printf 'Usage: bash %s [--dry-run] [--imac2011]\n' "$0"
            exit 0
            ;;
        *) printf 'Unknown option: %s\n' "$arg" >&2; exit 1 ;;
    esac
done

if (( ! dry_run )) &&
    pgrep -ix -u "$UID" 'xfconfd|xfce4-panel|xfce4-session|xfdesktop|xfwm4|Thunar|xfsettingsd' >/dev/null; then
    printf 'Log out of the graphical session and run this from a text console. XFCE or Xfconf is still running.\n' >&2
    exit 1
fi

if (( check_session )); then
    exit 0
fi

relative=xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
template="$package_dir/defaults/desktop/$relative"
destination="$config_dir/$relative"
directory=${destination%/*}
check_dir=$directory
while [[ $check_dir != "$config_dir" ]]; do
    if [[ -L $check_dir || ( -e $check_dir && ! -d $check_dir ) ]]; then
        printf 'Review the existing directory before restoring XFCE settings: %s\n' "$check_dir" >&2
        exit 1
    fi
    check_dir=${check_dir%/*}
done
if [[ -L $destination || ( -e $destination && ! -f $destination ) ]]; then
    printf 'Review the existing path before restoring XFCE settings: %s\n' "$destination" >&2
    exit 1
fi

stow_options=()
if (( dry_run )); then
    stow_options=(--dry-run)
fi
"$package_dir/../../bin/pm" stow "${stow_options[@]}" "${packages[@]}"

work_dir=$(mktemp -d)
staged=
trap 'rm -rf -- "$work_dir"; if [[ -n $staged ]]; then rm -f -- "$staged"; fi' EXIT
python3 -c '
import html
import pathlib
import sys

template, home = sys.argv[1:]
print(pathlib.Path(template).read_text().replace("@HOME@", html.escape(home, quote=True)), end="")
' "$template" "$HOME" > "$work_dir/xfce4-panel.xml"

if cmp -s -- "$work_dir/xfce4-panel.xml" "$destination"; then
    printf 'Already restored: %s\n' "$destination"
elif (( dry_run )); then
    if [[ -f $destination ]]; then
        printf 'Would back up and replace: %s\n' "$destination"
    else
        printf 'Would create: %s\n' "$destination"
    fi
else
    mkdir -p -- "$directory"
    staged=$(mktemp -- "$directory/.pm-xfce.XXXXXX")
    install -m 0644 -- "$work_dir/xfce4-panel.xml" "$staged"
    mv -vT --backup=numbered -- "$staged" "$destination"
    staged=
fi

if ( . /etc/os-release; [[ ${ID:-} == debian ]] ); then
    if (( dry_run )); then
        printf 'Would set GNOME color-scheme to prefer-dark and GTK theme to Adwaita-dark.\n'
    else
        dbus-run-session -- bash -e -c '
            gsettings set org.gnome.desktop.interface color-scheme prefer-dark
            gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
        '
    fi
fi
