#!/usr/bin/env bash

xfce4-terminal \
    --disable-server \
    --class=ScratchTerminal \
    --window \
    --title=cliamp \
    --dynamic-title-mode=none \
    --command="bash -lc 'cliamp; exec bash'" \
    --tab \
    --title=btop \
    --dynamic-title-mode=none \
    --command="bash -lc 'btop; exec bash'" \
    --tab \
    --title=pulsemixer \
    --dynamic-title-mode=none \
    --command="bash -lc 'pulsemixer; exec bash'"
