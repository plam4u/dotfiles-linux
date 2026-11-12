DOTFILES_ROOT=$(realpath -- "$HOME/.bashrc.d/00-shell.sh")
DOTFILES_ROOT=${DOTFILES_ROOT%/packages/shell/stow/*}
export DOTFILES_ROOT

. "$DOTFILES_ROOT/packages/shell/share/shell.sh"

alias so="source ~/.bashrc"
