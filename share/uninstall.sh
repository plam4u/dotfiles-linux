#!/usr/bin/env bash

# Script uninstallers use the same native removal policy as pm: no purge or autoremove.
remove_native_packages() {
    local target ID
    local -a installed=()
    . /etc/os-release
    for target in "$@"; do
        case $ID in
            debian)
                if [[ $(dpkg-query -W -f='${db:Status-Status}' -- "$target" 2>/dev/null) == installed ]]; then
                    installed+=("$target")
                fi
                ;;
            arch|omarchy)
                if pacman -Q -- "$target" >/dev/null 2>&1 || pacman -Qg -- "$target" >/dev/null 2>&1; then
                    installed+=("$target")
                fi
                ;;
            *) printf 'Unsupported distro: %s\n' "$ID" >&2; return 1 ;;
        esac
    done
    if (( ${#installed[@]} )); then
        case $ID in
            debian) sudo apt-get remove -y -- "${installed[@]}" ;;
            arch|omarchy) sudo pacman -R --noconfirm -- "${installed[@]}" ;;
        esac
    fi
}

remove_matching_file() {
    local reference=$1 destination=$2
    if [[ ! -e $destination && ! -L $destination ]]; then
        return 0
    fi
    if [[ ! -L $destination && -f $destination ]] && cmp -s -- "$reference" "$destination"; then
        sudo rm -v -- "$destination"
    else
        printf 'Keeping changed file: %s\n' "$destination" >&2
    fi
}

remove_vendor_package() {
    local package=$1 assets=$2 source_name=$3
    remove_native_packages "$package"
    remove_matching_file "$assets/$source_name" "/etc/apt/sources.list.d/$source_name"
    remove_matching_file "$assets/$package-archive-keyring.gpg" "/usr/share/keyrings/$package-archive-keyring.gpg"
}
