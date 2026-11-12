if pm_package_dir=$(realpath -- "$HOME/.zshrc.d/00-shell.sh"); then
    pm_package_dir=${pm_package_dir%/stow/.zshrc.d/00-shell.sh}
    . "$pm_package_dir/share/shell.sh"
fi
unset pm_package_dir

alias so="source ~/.zshrc"
