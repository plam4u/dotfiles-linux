_pm_source_deno() {
    local package_dir
    package_dir=$(realpath -- "$HOME/.zshrc.d/deno.sh") || return
    package_dir=${package_dir%/stow/.zshrc.d/deno.sh}
    . "$package_dir/share/deno.sh"
}

_pm_source_deno
unset -f _pm_source_deno

# Run before compinit so Zsh discovers the generated completion.
if [[ -d "$HOME/.zsh/completions" && ":$FPATH:" != *":$HOME/.zsh/completions:"* ]]; then
    fpath=("$HOME/.zsh/completions" "${fpath[@]}")
fi
