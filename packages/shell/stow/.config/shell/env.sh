if [ -d "$HOME/bin" ]; then
    case ":${PATH:-}:" in
        *":$HOME/bin:"*) ;;
        *) export PATH="$HOME/bin${PATH:+:$PATH}" ;;
    esac
fi

if [ -r "$HOME/.deno/env" ]; then
    . "$HOME/.deno/env"
fi

if [ -r "$HOME/.config/shell/pm-path.sh" ]; then
    . "$HOME/.config/shell/pm-path.sh"
fi

if [ -d "$HOME/dev/neovim/build/bin" ]; then
    case ":$PATH:" in
        *":$HOME/dev/neovim/build/bin:"*) ;;
        *) export PATH="$HOME/dev/neovim/build/bin:$PATH" ;;
    esac
fi

# Default editors while preserving existing preferences.
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
