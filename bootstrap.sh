#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

usage() {
    printf 'Usage: %s [--bundle NAME]... [--dry-run]\n' "${0##*/}"
    printf 'Defaults to the basics bundle. Repeat --bundle to combine bundles.\n'
    printf 'Use --dry-run to preview installation and config links.\n'
    printf '\nBundles in this checkout\n'
    local file
    for file in bundles/*; do
        [[ -f $file ]] || continue
        printf '  %s\n' "${file##*/}"
    done
}

bundles=()
dry_run=0
while (( $# )); do
    case $1 in
        --bundle)
            if (( $# < 2 )) || [[ -z $2 || $2 == -* ]]; then
                usage >&2
                exit 1
            fi
            bundles+=("$2")
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
if (( ! ${#bundles[@]} )); then
    bundles=(basics)
fi

architecture=$(uname -m)
case "$ID:$architecture" in
    *:x86_64|debian:aarch64) ;;
    *)
        printf 'This bootstrap supports x86-64 and the basics on Debian ARM64.\n' >&2
        exit 1
        ;;
esac

install=()
desktop_options=()
restore_common=0
restore_desktop=0
for bundle in "${bundles[@]}"; do
    if [[ $architecture == aarch64 && $bundle != basics ]]; then
        printf 'On Debian ARM64, run ./bootstrap.sh for the basics. The %s bundle requires x86-64.\n' "$bundle" >&2
        exit 1
    fi
    case $bundle in
        starter) restore_common=1 ;;
        debian-workstation|arch-workstation)
            if [[ $bundle != "$ID-workstation" ]]; then
                printf 'Use --bundle %s-workstation on this distro.\n' "$ID" >&2
                exit 1
            fi
            restore_common=1
            restore_desktop=1
            ;;
        debian-imac12-2-firmware)
            model=
            if [[ -r /sys/devices/virtual/dmi/id/product_name ]]; then
                read -r model < /sys/devices/virtual/dmi/id/product_name
            fi
            if [[ $ID != debian || $model != iMac12,2 ]]; then
                printf 'The firmware bundle requires Debian on an iMac12,2.\n' >&2
                exit 1
            fi
            desktop_options=(--imac12-2)
            ;;
    esac
    install+=(--bundle "$bundle")
done

if (( dry_run )); then
    ./bin/pm install --dry-run "${install[@]}"
    exit
fi

if (( restore_desktop )); then
    bash packages/xfce4/post-install.sh --check-session
fi
./bin/pm install "${install[@]}"
if (( restore_common )); then
    bash packages/common-tools/post-install.sh
fi
if (( restore_desktop )); then
    bash packages/xfce4/post-install.sh "${desktop_options[@]}"
    dbus-run-session -- bash packages/xfce4-terminal/post-install.sh
    bash packages/cliamp/post-install.sh
    printf '\nSign in again or reboot to load the desktop settings.\n'
fi

printf '\nBootstrap complete. Open a new shell to use pm from anywhere.\n'
