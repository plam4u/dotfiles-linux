#!/usr/bin/env bash
set -euo pipefail

install_dotfiles() {
    if (( EUID == 0 )); then
        printf 'Run the installer as your regular user. It requests sudo when needed.\n' >&2
        exit 1
    fi
    . /etc/os-release
    case ${ID:-}:${VERSION_CODENAME:-} in
        debian:trixie|arch:*) ;;
        *) printf 'This installer supports Debian 13 and Arch Linux.\n' >&2; exit 1 ;;
    esac
    if ! command -v git >/dev/null; then
        case $ID in
            debian)
                sudo apt-get update
                sudo apt-get install -y git ca-certificates
                ;;
            arch) sudo pacman -S --needed --noconfirm git ;;
        esac
    fi

    local checkout="$HOME/dotfiles-debian"
    local remote=https://github.com/plam4u/dotfiles-debian.git
    if [[ -e $checkout || -L $checkout ]]; then
        local origin=
        if [[ -e $checkout/.git ]]; then
            origin=$(git -C "$checkout" remote get-url origin 2>/dev/null) || origin=
        fi
        case $origin in
            "$remote"|git@github.com:plam4u/dotfiles-debian.git) ;;
            *) printf 'Review the existing path before retrying: %s\n' "$checkout" >&2; exit 1 ;;
        esac
        if [[ ! -f $checkout/bootstrap.sh ]]; then
            printf 'Update the existing checkout at %s to get bootstrap.sh.\n' "$checkout" >&2
            exit 1
        fi
    else
        GIT_TERMINAL_PROMPT=0 git clone --branch main -- "$remote" "$checkout"
    fi

    printf '\nRun this to install the basics:\n  %q\n' "$checkout/bootstrap.sh"
}

install_dotfiles
