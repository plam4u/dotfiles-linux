#!/usr/bin/env bash
set -euo pipefail

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

checkout="$HOME/dotfiles-debian"
remote=https://github.com/plam4u/dotfiles-debian.git
if [[ -e $checkout || -L $checkout ]]; then
    if [[ ! -e $checkout/.git ]]; then
        printf 'Review the existing path before retrying: %s\n' "$checkout" >&2
        exit 1
    fi
    origin=$(git -C "$checkout" remote get-url origin 2>/dev/null) || origin=
    case $origin in
        "$remote"|git@github.com:plam4u/dotfiles-debian.git) ;;
        *) printf 'Review the existing path before retrying: %s\n' "$checkout" >&2; exit 1 ;;
    esac
    if [[ ! -f $checkout/bootstrap.sh ]]; then
        printf 'Update the existing checkout at %s to get bootstrap.sh.\n' "$checkout" >&2
        exit 1
    fi
else
    git_options=()
    if command -v gh >/dev/null && gh auth status --hostname github.com >/dev/null 2>&1; then
        git_options=(-c credential.helper= -c 'credential.helper=!gh auth git-credential')
    fi
    git "${git_options[@]}" clone --branch main -- "$remote" "$checkout"
fi

exec bash "$checkout/bootstrap.sh" "$@"
