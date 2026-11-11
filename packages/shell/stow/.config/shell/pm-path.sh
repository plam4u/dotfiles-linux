_pm_setup_path() {
    local snippet checkout directory
    snippet=$(realpath -- "$HOME/.config/shell/pm-path.sh") || return
    checkout=${snippet%/packages/shell/stow/.config/shell/pm-path.sh}
    if [ "$checkout" = "$snippet" ]; then
        checkout="$HOME/dotfiles-linux"
    fi

    for directory in "$HOME/.local/bin" "$checkout/bin"; do
        case ":${PATH:-}:" in
            *":$directory:"*) ;;
            *) export PATH="$directory${PATH:+:$PATH}" ;;
        esac
    done
}

_pm_setup_path
unset -f _pm_setup_path
