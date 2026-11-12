if pm_package_dir=$(realpath -- "$HOME/.bashrc.d/deno.sh"); then
    pm_package_dir=${pm_package_dir%/stow/.bashrc.d/deno.sh}
    . "$pm_package_dir/share/deno.sh"
fi
unset pm_package_dir

if [ -r "$HOME/.local/share/bash-completion/completions/deno.bash" ]; then
    . "$HOME/.local/share/bash-completion/completions/deno.bash"
fi
