if [ -d "$HOME/bin" ]; then
    case ":${PATH:-}:" in
        *":$HOME/bin:"*) ;;
        *) export PATH="$HOME/bin${PATH:+:$PATH}" ;;
    esac
fi

# Default editors while preserving existing preferences.
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"

_pm_setup_path() {
    local checkout directory
    checkout=${package_dir%/packages/shell}

    for directory in "$HOME/.local/bin" "$checkout/bin"; do
        case ":${PATH:-}:" in
            *":$directory:"*) ;;
            *) export PATH="$directory${PATH:+:$PATH}" ;;
        esac
    done
}

_pm_setup_path
unset -f _pm_setup_path

# Aliases and colors are only needed in interactive shells.
case $- in
    *i*) ;;
    *) return ;;
esac

# Interactive settings shared by Bash and Zsh.
if command -v dircolors >/dev/null 2>&1; then
    if [ -r "$HOME/.dircolors" ]; then
        eval "$(dircolors -b "$HOME/.dircolors")"
    else
        eval "$(dircolors -b)"
    fi
    alias ls='ls --color=auto'
fi

alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
