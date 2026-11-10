# Load the interactive Bash settings when Bash starts as a login shell.
if [ -n "${BASH_VERSION:-}" ] && [ -r "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

if [ -d "$HOME/bin" ]; then
    case ":${PATH:-}:" in
        *":$HOME/bin:"*) ;;
        *) export PATH="$HOME/bin${PATH:+:$PATH}" ;;
    esac
fi

if [ -r "$HOME/.config/shell/pm-path.sh" ]; then
    . "$HOME/.config/shell/pm-path.sh"
fi
if [ -r "$HOME/.deno/env" ]; then
    . "$HOME/.deno/env"
fi
