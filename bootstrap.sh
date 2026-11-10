#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: %s [--profile basics|starter|workstation|imac] [--dry-run]\n' "${0##*/}"
}

profile=basics
dry_run=0
while (( $# )); do
    case $1 in
        --profile)
            (( $# >= 2 )) || { usage >&2; exit 1; }
            profile=$2
            shift
            ;;
        --dry-run) dry_run=1 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 1 ;;
    esac
    shift
done

if (( EUID == 0 )); then
    printf 'Run the bootstrap as your regular user. It requests sudo when needed.\n' >&2
    exit 1
fi
. /etc/os-release
case ${ID:-}:${VERSION_CODENAME:-} in
    debian:trixie|arch:*) ;;
    *) printf 'This bootstrap supports Debian 13 and Arch Linux.\n' >&2; exit 1 ;;
esac
if [[ $(uname -m) != x86_64 ]]; then
    printf 'This bootstrap requires an x86-64 system.\n' >&2
    exit 1
fi

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

desktop_options=()
case $profile in
    basics) install=(stow shell tmux vim) ;;
    starter) install=(--bundle starter) ;;
    workstation) install=(--bundle "$ID-workstation" restic) ;;
    imac)
        model=
        if [[ -r /sys/devices/virtual/dmi/id/product_name ]]; then
            read -r model < /sys/devices/virtual/dmi/id/product_name
        fi
        if [[ $ID != debian || $model != iMac12,2 ]]; then
            printf 'The iMac profile requires Debian on an iMac12,2. Choose workstation for a VM.\n' >&2
            exit 1
        fi
        install=(--bundle debian-workstation --bundle debian-imac12-2-firmware restic)
        desktop_options=(--imac12-2)
        ;;
    *) usage >&2; exit 1 ;;
esac

if (( dry_run )); then
    ./bin/pm install --dry-run "${install[@]}"
    exit
fi

if [[ $profile == workstation || $profile == imac ]]; then
    bash packages/xfce4/post-install.sh --check-session
fi
./bin/pm install "${install[@]}"
if [[ $profile != basics ]]; then
    bash packages/common-tools/post-install.sh
fi
if [[ $profile == workstation || $profile == imac ]]; then
    bash packages/xfce4/post-install.sh "${desktop_options[@]}"
    dbus-run-session -- bash packages/xfce4-terminal/post-install.sh
    bash packages/cliamp/post-install.sh
    printf '\nSign in again or reboot to load the desktop settings.\n'
fi

printf '\nBootstrap complete. Open a new shell to use pm from anywhere.\n'
