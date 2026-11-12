if pm_package_dir=$(realpath -- "$HOME/.bashrc.d/00-shell.sh"); then
    pm_package_dir=${pm_package_dir%/stow/.bashrc.d/00-shell.sh}
    . "$pm_package_dir/share/shell.sh"
fi
unset pm_package_dir

alias so="source ~/.bashrc"
