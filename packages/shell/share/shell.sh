if [ -d "$HOME/bin" ]; then
    case ":${PATH:-}:" in
        *":$HOME/bin:"*) ;;
        *) export PATH="$HOME/bin${PATH:+:$PATH}" ;;
    esac
fi

# Default editors while preserving existing preferences.
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"

for pm_directory in "$HOME/.local/bin" "${pm_package_dir%/packages/shell}/bin"; do
    case ":${PATH:-}:" in
        *":$pm_directory:"*) ;;
        *) export PATH="$pm_directory${PATH:+:$PATH}" ;;
    esac
done
unset pm_directory

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
