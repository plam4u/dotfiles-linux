#!/bin/sh
if [ -n "${WAYLAND_DISPLAY:-}" ] || [ "${XDG_SESSION_TYPE:-}" = wayland ]; then
    exit 0
fi
setxkbmap -layout us -variant altgr-intl
