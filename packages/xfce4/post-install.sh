#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_dir=${XDG_CONFIG_HOME:-$HOME/.config}
profiles=(desktop)
dry_run=0
check_session=0

for arg in "$@"; do
    case $arg in
        --dry-run) dry_run=1 ;;
        --check-session) check_session=1 ;;
        --imac2011) profiles=(desktop imac2011) ;;
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

work_dir=$(mktemp -d)
staged=
trap 'rm -rf -- "$work_dir"; if [[ -n $staged ]]; then rm -f -- "$staged"; fi' EXIT

sources=()
destinations=()
for profile in "${profiles[@]}"; do
    profile_dir="$package_dir/defaults/$profile"
    find "$profile_dir" -type f -print0 | sort -z > "$work_dir/files"
    while IFS= read -r -d '' source; do
        relative=${source#"$profile_dir/"}
        destination="$config_dir/$relative"
        directory=${destination%/*}
        while [[ $directory != "$config_dir" ]]; do
            if [[ -L $directory || ( -e $directory && ! -d $directory ) ]]; then
                printf 'Review the existing directory before restoring XFCE settings: %s\n' "$directory" >&2
                exit 1
            fi
            directory=${directory%/*}
        done
        if [[ -L $destination || ( -e $destination && ! -f $destination ) ]]; then
            printf 'Review the existing path before restoring XFCE settings: %s\n' "$destination" >&2
            exit 1
        fi
        if [[ $relative == */xfce4-panel.xml ]]; then
            python3 -c '
import html
import pathlib
import sys

template, home = sys.argv[1:]
print(pathlib.Path(template).read_text().replace("@HOME@", html.escape(home, quote=True)), end="")
' "$source" "$HOME" > "$work_dir/xfce4-panel.xml"
            source="$work_dir/xfce4-panel.xml"
        fi
        sources+=("$source")
        destinations+=("$destination")
    done < "$work_dir/files"
done

for index in "${!sources[@]}"; do
    source=${sources[index]}
    destination=${destinations[index]}
    if cmp -s -- "$source" "$destination"; then
        printf 'Already restored: %s\n' "$destination"
    elif (( dry_run )); then
        if [[ -f $destination ]]; then
            printf 'Would back up and replace: %s\n' "$destination"
        else
            printf 'Would create: %s\n' "$destination"
        fi
    else
        directory=${destination%/*}
        mkdir -p -- "$directory"
        staged=$(mktemp -- "$directory/.pm-xfce.XXXXXX")
        install -m 0644 -- "$source" "$staged"
        mv -vT --backup=numbered -- "$staged" "$destination"
        staged=
    fi
done

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
