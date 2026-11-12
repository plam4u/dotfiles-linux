#!/usr/bin/env bash

download_verified() {
    local url=$1 digest=$2 destination=$3
    curl --fail --silent --show-error --location --proto '=https' \
        --output "$destination" "$url" &&
        printf '%s  %s\n' "$digest" "$destination" | sha256sum --check --status || {
            printf 'Could not download or verify %s.\n' "${url##*/}" >&2
            return 1
        }
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

install_user_binary() (
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
    trap 'rm -r -- "$work_dir"' EXIT
    download_verified "$url" "$digest" "$work_dir/$name" || return 1
    install -D -m 0755 -- "$work_dir/$name" "$destination"
)
