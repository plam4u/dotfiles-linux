#!/usr/bin/env bash
set -euo pipefail

destination="$HOME/.oh-my-bash"
if [[ -r $destination/oh-my-bash.sh ]]; then
    printf '  Already installed: %s\n' "$destination"
    exit 0
fi
if [[ -e $destination || -L $destination ]]; then
    printf 'Review the existing path at %s before retrying.\n' "$destination" >&2
    exit 1
fi

work_dir=$(mktemp -d "$HOME/.oh-my-bash.XXXXXX")
trap 'rm -r -- "$work_dir"' EXIT

git clone --depth 1 https://github.com/ohmybash/oh-my-bash.git "$work_dir/oh-my-bash"
mv -nT -- "$work_dir/oh-my-bash" "$destination"
[[ -r $destination/oh-my-bash.sh ]]
