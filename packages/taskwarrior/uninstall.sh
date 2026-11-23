#!/usr/bin/env bash
set -euo pipefail

prefix="$HOME/.local/opt/taskwarrior-3.5.0"
link="$HOME/.local/bin/task"

if [[ -L $link && $(readlink -- "$link") == "$prefix/bin/task" ]]; then
    rm -v -- "$link"
fi
rm -rfv -- "$prefix"
