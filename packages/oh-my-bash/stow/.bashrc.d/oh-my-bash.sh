if [[ -r ${OSH:-$HOME/.oh-my-bash}/oh-my-bash.sh ]]; then
    export OSH="${OSH:-$HOME/.oh-my-bash}"
    OSH_THEME="${OSH_THEME:-purity}"
    # Save Powerbash10k settings here. The pb10k show/hide commands change
    # only the current shell and its children.
    # THEME_SHOW_CLOCK=false
    # THEME_SHOW_PYTHON=true
    # __PB10K_TOP_LEFT="dir scm"
    # __PB10K_TOP_RIGHT="exitcode cmd_duration user_info python ruby todo clock battery"
    # __PB10K_BOTTOM="char"

    DISABLE_AUTO_UPDATE="${DISABLE_AUTO_UPDATE:-true}"
    # Keep arrays set by earlier startup fragments, including empty arrays.
    if ! declare -p plugins >/dev/null 2>&1; then
        plugins=(git)
    fi
    if ! declare -p completions >/dev/null 2>&1; then
        completions=(git ssh)
    fi
    . "$OSH/oh-my-bash.sh"
fi
