_pm_source_deno() {
    local package_dir
    package_dir=$(realpath -- "$HOME/.bashrc.d/deno.sh") || return
    package_dir=${package_dir%/stow/.bashrc.d/deno.sh}
    . "$package_dir/share/deno.sh"
}

_pm_source_deno
unset -f _pm_source_deno

if [ -r "$HOME/.local/share/bash-completion/completions/deno.bash" ]; then
    . "$HOME/.local/share/bash-completion/completions/deno.bash"
fi
