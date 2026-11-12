if [ -r "$HOME/.config/shell/env.sh" ]; then
    . "$HOME/.config/shell/env.sh"
fi

# Load the interactive Bash settings when Bash starts as a login shell.
if [ -n "${BASH_VERSION:-}" ] && [ -r "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
