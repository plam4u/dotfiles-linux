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

install=()
desktop_options=()
restore_desktop=0
for bundle in "${bundles[@]}"; do
    case $bundle in
        debian-workstation|arch-workstation)
            if [[ $bundle != "$ID-workstation" ]]; then
                printf 'Use --bundle %s-workstation on this distro.\n' "$ID" >&2
                exit 1
            fi
            restore_desktop=1
            ;;
        imac2011)
            model=
            if [[ -r /sys/devices/virtual/dmi/id/product_name ]]; then
                read -r model < /sys/devices/virtual/dmi/id/product_name
            fi
            if [[ $ID == debian && $model == iMac12,2 ]]; then
                desktop_options=(--imac2011)
            fi
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
if (( restore_desktop )); then
    bash packages/xfce4/post-install.sh "${desktop_options[@]}"
    dbus-run-session -- bash packages/xfce4-terminal/post-install.sh
    printf '\nSign in again or reboot to load the desktop settings.\n'
fi

printf '\nPackage installation complete. Manage packages with:\n  %q\n' "$PWD/bin/pm"
if (( ! restore_desktop )); then
    printf '\nFor the full workstation setup, first run:\n  %q --bundle %s-workstation\n' "$PWD/bootstrap.sh" "$ID"
fi
printf '\nAfter reinstalling, setup is not complete until you restore private settings.\n'
printf 'Restore instructions:\n  %s/packages/restic/README.md\n' "$PWD"
