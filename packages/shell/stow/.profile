if [ -r "$HOME/.bashrc.d/00-shell.sh" ]; then
    . "$HOME/.bashrc.d/00-shell.sh"
fi

# Load the interactive Bash settings when Bash starts as a login shell.
if [ -n "${BASH_VERSION:-}" ] && [ -r "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
