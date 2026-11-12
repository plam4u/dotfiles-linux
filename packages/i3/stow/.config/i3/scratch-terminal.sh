#!/usr/bin/env bash

set -euo pipefail

if ! tmux has-session -t '=scratch' 2>/dev/null; then
    tmux new-session -d -s scratch -n audio "bash -lc 'cliamp; exec bash'" \; \
        set-option -t scratch base-index 1 \; \
        move-window -r -t scratch \; \
        set-window-option -t scratch:audio automatic-rename off \; \
        split-window -v -t scratch:audio "bash -lc 'pulsemixer; exec bash'" \; \
        select-pane -t scratch:audio -U \; \
        new-window -t scratch:2 -n btop "bash -lc 'btop; exec bash'" \; \
        set-window-option -t scratch:btop automatic-rename off \; \
        select-window -t scratch:audio
fi

exec xfce4-terminal \
    --disable-server \
    --class=ScratchTerminal \
    --window \
    --title=scratch \
    --dynamic-title-mode=none \
    --command="tmux attach-session -t '=scratch'"
