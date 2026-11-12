#!/usr/bin/env bash
set -euo pipefail

if [[ $(uname -s) == Darwin ]]; then
    exec brew uninstall --cask codex
fi

module="$HOME/.local/lib/node_modules/@openai/codex"
if [[ ! -e $module && ! -L $module ]]; then
    printf 'Not installed under ~/.local: @openai/codex\n'
    exit 0
fi
npm uninstall --global --prefix "$HOME/.local" @openai/codex
