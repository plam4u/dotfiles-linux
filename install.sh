#!/usr/bin/env bash
set -euo pipefail

install_dotfiles() {
    if (( EUID == 0 )); then
        printf 'Run the bootstrap as your regular user. It requests sudo when needed.\n' >&2
        exit 1
    fi
    . /etc/os-release
    if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie || $(dpkg --print-architecture) != amd64 ]]; then
        printf 'This bootstrap requires Debian 13 (amd64).\n' >&2
        exit 1
    fi

    if ! command -v git >/dev/null; then
        sudo apt-get update
        sudo apt-get install -y git ca-certificates
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

    # Read menu input from the terminal when the launcher arrives over a pipe.
    if [[ ! -t 0 && -t 1 ]]; then
        exec </dev/tty
    fi
    exec bash "$checkout/bootstrap.sh" "$@"
}

install_dotfiles "$@"
