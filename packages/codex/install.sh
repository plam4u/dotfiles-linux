#!/usr/bin/env bash
set -euo pipefail

if command -v codex >/dev/null; then
    printf 'Already installed: %s\n' "$(command -v codex)"
    exit 0
fi

if [[ $(uname -s) == Darwin ]]; then
    if ! command -v brew >/dev/null; then
        printf 'Install Homebrew from https://brew.sh, then run this script again.\n' >&2
        exit 1
    fi
    exec brew install --cask codex
fi

destination="$HOME/.local/bin/codex"
if [[ -e $destination || -L $destination ]]; then
    printf 'Review the existing path at %s before retrying.\n' "$destination" >&2
    exit 1
fi
npm install --global --prefix "$HOME/.local" @openai/codex@latest
"$destination" --version
printf 'Run %q to sign in. Add ~/.local/bin to PATH to use codex by name.\n' "$destination"
