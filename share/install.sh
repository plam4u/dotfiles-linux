#!/usr/bin/env bash

download_verified() {
    local url=$1 digest=$2 destination=$3
    curl --fail --silent --show-error --location --proto '=https' \
        --output "$destination" "$url" &&
        printf '%s  %s\n' "$digest" "$destination" | sha256sum --check --status
}

install_vendor_package() {
    local package=$1 assets=$2 source_name=$3
    local source="/etc/apt/sources.list.d/$source_name"
    local key="/usr/share/keyrings/$package-archive-keyring.gpg"
    local changed=0

    if [[ -e $source || -L $source ]] && ! cmp -s "$assets/$source_name" "$source"; then
        printf 'Review the existing APT source at %s before installing %s.\n' "$source" "$package" >&2
        return 1
    fi
    if [[ ! -s $key ]]; then
        sudo install -m 0644 -- "$assets/${key##*/}" "$key"
        changed=1
    fi
    if [[ ! -e $source ]]; then
        sudo install -m 0644 -- "$assets/$source_name" "$source"
        changed=1
    fi

    if (( changed )); then
        sudo apt-get update
    fi
    if [[ $(dpkg-query -W -f='${Status}' -- "$package" 2>/dev/null) == 'install ok installed' ]]; then
        printf '  Already installed: %s\n' "$package"
        return
    fi
    if (( ! changed )); then
        sudo apt-get update
    fi
    sudo apt-get install -y --no-remove -- "$package"
}

install_user_binary() {
    local name=$1 url=$2 digest=$3
    local destination="$HOME/.local/bin/$name"
    if [[ -x $destination && -f $destination ]]; then
        printf '  Already installed: %s\n' "$destination"
        return
    fi
    if [[ -e $destination || -L $destination ]]; then
        printf 'Review the existing file at %s before retrying.\n' "$destination" >&2
        return 1
    fi

    local work_dir
    work_dir=$(mktemp -d)
    (
        trap 'rm -r -- "$work_dir"' EXIT
        if ! download_verified "$url" "$digest" "$work_dir/$name"; then
            printf 'Could not download or verify %s.\n' "$name" >&2
            exit 1
        fi
        install -D -m 0755 -- "$work_dir/$name" "$destination"
    )
}

restore_user_settings() (
    local defaults=$1
    shift
    local dry_run=0
    if [[ ${1:-} == --dry-run ]]; then
        dry_run=1
        shift
    fi
    if (( $# )); then
        printf 'Usage: bash %s [--dry-run]\n' "$0" >&2
        return 1
    fi

    local config_dir=${XDG_CONFIG_HOME:-$HOME/.config}
    local source destination directory staged=
    local -a files
    shopt -s globstar nullglob
    files=("$defaults"/**/*)
    trap 'if [[ -n $staged ]]; then rm -f -- "$staged"; fi' EXIT

    for source in "${files[@]}"; do
        [[ -f $source ]] || continue
        destination="$config_dir/${source#"$defaults/"}"
        directory=${destination%/*}
        while [[ $directory != "$config_dir" ]]; do
            if [[ -L $directory || ( -e $directory && ! -d $directory ) ]]; then
                printf 'Review the existing directory before restoring settings: %s\n' "$directory" >&2
                return 1
            fi
            directory=${directory%/*}
        done
        if [[ -L $destination || ( -e $destination && ! -f $destination ) ]]; then
            printf 'Review the existing path before restoring settings: %s\n' "$destination" >&2
            return 1
        fi
    done

    for source in "${files[@]}"; do
        [[ -f $source ]] || continue
        destination="$config_dir/${source#"$defaults/"}"
        if cmp -s -- "$source" "$destination"; then
            printf 'Already restored: %s\n' "$destination"
        elif (( dry_run )); then
            if [[ -f $destination ]]; then
                printf 'Would back up and replace: %s\n' "$destination"
            else
                printf 'Would create: %s\n' "$destination"
            fi
        else
            directory=${destination%/*}
            mkdir -p -- "$directory"
            staged=$(mktemp -- "$directory/.pm-settings.XXXXXX")
            install -m 0600 -- "$source" "$staged"
            mv -vT --backup=numbered -- "$staged" "$destination"
            staged=
        fi
    done
)
