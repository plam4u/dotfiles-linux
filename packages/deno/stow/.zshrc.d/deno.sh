. "$DOTFILES_ROOT/packages/deno/share/deno.sh"

# Run before compinit so Zsh discovers the generated completion.
if [[ -d "$HOME/.zsh/completions" && ":$FPATH:" != *":$HOME/.zsh/completions:"* ]]; then
    fpath=("$HOME/.zsh/completions" "${fpath[@]}")
fi
