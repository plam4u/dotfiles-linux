_pm_source_shell() {
    local package_dir
    package_dir=$(realpath -- "$HOME/.bashrc.d/00-shell.sh") || return
    package_dir=${package_dir%/stow/.bashrc.d/00-shell.sh}
    . "$package_dir/share/shell.sh"
}

_pm_source_shell
unset -f _pm_source_shell

alias so="source ~/.bashrc"
