#!/usr/bin/env bash
set -euo pipefail

rm -fv -- "$HOME/.deno/bin/deno" \
    "$HOME/.local/share/bash-completion/completions/deno.bash" \
    "$HOME/.zsh/completions/_deno"
