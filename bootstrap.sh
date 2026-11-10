#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: %s [--profile workstation|starter|imac] [--dry-run]\n' "${0##*/}"
}

profile=
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
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie || $(dpkg --print-architecture) != amd64 ]]; then
    printf 'This bootstrap requires Debian 13 (amd64).\n' >&2
    exit 1
fi

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
model=
if [[ -r /sys/devices/virtual/dmi/id/product_name ]]; then
    read -r model < /sys/devices/virtual/dmi/id/product_name
fi
if [[ -z $profile ]]; then
    printf '1) Debian workstation (default)\n2) Starter packages\n'
    if [[ $model == iMac12,2 ]]; then
        printf '3) iMac12,2 workstation and hardware settings\n'
    fi
    if ! read -r -p 'Select a profile [1] ' choice; then
        printf 'Choose a profile in a terminal or pass --profile.\n' >&2
        exit 1
    fi
    case ${choice:-1} in
        1) profile=workstation ;;
        2) profile=starter ;;
        3) profile=imac ;;
        *) printf 'Unknown profile selection.\n' >&2; exit 1 ;;
    esac
fi

desktop_options=()
case $profile in
    workstation) install=(--bundle debian-workstation restic) ;;
    starter) install=(--bundle starter) ;;
    imac)
        if [[ $model != iMac12,2 ]]; then
            printf 'The iMac profile requires an iMac12,2. Choose the workstation profile for a VM.\n' >&2
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

if [[ $profile != starter ]]; then
    bash packages/xfce4/post-install.sh --check-session
fi
./bin/pm install "${install[@]}"
printf '\nApplying the saved settings from the listed follow-ups.\n'
bash packages/common-tools/post-install.sh
if [[ $profile != starter ]]; then
    bash packages/xfce4/post-install.sh "${desktop_options[@]}"
    dbus-run-session -- bash packages/xfce4-terminal/post-install.sh
    bash packages/cliamp/post-install.sh
fi

printf '\nBootstrap complete. Sign in again or reboot to load the installed settings.\n'
