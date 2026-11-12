if pm_package_dir=$(realpath -- "$HOME/.zshrc.d/deno.sh"); then
    pm_package_dir=${pm_package_dir%/stow/.zshrc.d/deno.sh}
    . "$pm_package_dir/share/deno.sh"
fi
unset pm_package_dir

# Run before compinit so Zsh discovers the generated completion.
if [[ -d "$HOME/.zsh/completions" && ":$FPATH:" != *":$HOME/.zsh/completions:"* ]]; then
    fpath=("$HOME/.zsh/completions" "${fpath[@]}")
fi
