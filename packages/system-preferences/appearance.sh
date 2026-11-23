#!/usr/bin/env bash
set -euo pipefail

. /etc/os-release
if [[ $ID == omarchy ]]; then
    printf 'Keeping the active Omarchy theme.\n'
    exit 0
fi

dry_run=0
case ${1:-} in
    --dry-run) dry_run=1 ;;
    '') ;;
    *) printf 'Usage: bash %s [--dry-run]\n' "$0" >&2; exit 1 ;;
esac
(( $# <= 1 )) || { printf 'Too many arguments.\n' >&2; exit 1; }

if ! command -v gsettings >/dev/null && ! command -v xfconf-query >/dev/null; then
    printf 'Skipping desktop appearance: neither GSettings nor Xfconf is installed.\n'
    exit 0
fi
if (( ! dry_run )) && [[ -z ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
    exec dbus-run-session -- bash "$0" "$@"
fi

run() {
    printf '  +'
    printf ' %q' "$@"
    printf '\n'
    if (( ! dry_run )); then
        "$@"
    fi
}

if command -v gsettings >/dev/null &&
    gsettings list-schemas | grep -Fx org.gnome.desktop.interface >/dev/null; then
    run gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    run gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
fi

if ! command -v xfconf-query >/dev/null; then
    printf 'Skipping XFCE appearance: Xfconf is not installed.\n'
    exit 0
fi

config_home=${XDG_CONFIG_HOME:-$HOME/.config}
declare -A backed_up=()
staged=
trap 'if [[ -n $staged ]]; then rm -f -- "$staged"; fi' EXIT

while IFS=$'\t' read -r channel property type value; do
    if (( ! dry_run )); then
        if current=$(xfconf-query --channel "$channel" --property "$property" 2>/dev/null) &&
            [[ $current == "$value" ]]; then
            continue
        fi
        # Detach Stow links before Xfconf writes, preserving the original as a backup.
        file="$config_home/xfce4/xfconf/xfce-perchannel-xml/$channel.xml"
        if [[ ! ${backed_up[$channel]+set} ]]; then
            if [[ -e $file || -L $file ]]; then
                [[ -f $file ]] || { printf 'Review the existing path: %s\n' "$file" >&2; exit 1; }
                staged=$(mktemp -- "${file%/*}/.pm-appearance.XXXXXX")
                cp -p -- "$file" "$staged"
                mv -vT --backup=numbered -- "$staged" "$file"
                staged=
            fi
            backed_up[$channel]=1
        fi
    fi
    run xfconf-query --channel "$channel" --property "$property" --create --type "$type" --set "$value"
done <<'PREFERENCES'
xsettings	/Net/ThemeName	string	Adwaita-dark
xsettings	/Xft/Antialias	int	1
xsettings	/Gtk/CursorThemeName	string	Adwaita
xsettings	/Gtk/DecorationLayout	string	icon,menu:minimize,maximize,close
xsettings	/Gdk/WindowScalingFactor	int	1
xsettings	/Xfce/SyncThemes	bool	true
xfwm4	/general/borderless_maximize	bool	true
xfwm4	/general/box_move	bool	false
xfwm4	/general/box_resize	bool	false
xfwm4	/general/button_layout	string	O|HMC
xfwm4	/general/button_offset	int	0
xfwm4	/general/button_spacing	int	0
xfwm4	/general/cycle_draw_frame	bool	true
xfwm4	/general/cycle_preview	bool	true
xfwm4	/general/frame_opacity	int	100
xfwm4	/general/frame_border_top	int	0
xfwm4	/general/full_width_title	bool	true
xfwm4	/general/inactive_opacity	int	100
xfwm4	/general/maximized_offset	int	0
xfwm4	/general/move_opacity	int	100
xfwm4	/general/popup_opacity	int	100
xfwm4	/general/resize_opacity	int	100
xfwm4	/general/shadow_delta_height	int	0
xfwm4	/general/shadow_delta_width	int	0
xfwm4	/general/shadow_delta_x	int	0
xfwm4	/general/shadow_delta_y	int	-3
xfwm4	/general/shadow_opacity	int	50
xfwm4	/general/show_app_icon	bool	false
xfwm4	/general/show_dock_shadow	bool	true
xfwm4	/general/show_frame_shadow	bool	true
xfwm4	/general/show_popup_shadow	bool	false
xfwm4	/general/theme	string	Default-hdpi
xfwm4	/general/title_alignment	string	center
xfwm4	/general/title_font	string	Sans Bold 9
xfwm4	/general/title_horizontal_offset	int	0
xfwm4	/general/titleless_maximize	bool	false
xfwm4	/general/title_shadow_active	string	false
xfwm4	/general/title_shadow_inactive	string	false
xfwm4	/general/title_vertical_offset_active	int	0
xfwm4	/general/title_vertical_offset_inactive	int	0
xfwm4	/general/use_compositing	bool	true
PREFERENCES
