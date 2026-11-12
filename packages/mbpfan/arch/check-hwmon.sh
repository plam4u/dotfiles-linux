#!/usr/bin/env bash
set -euo pipefail

binary=$1
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
for mode in hwmon platform; do
    device="$fixture/$mode"
    directory=$device
    if [[ $mode == hwmon ]]; then
        directory="$device/hwmon/hwmon27"
    fi
    mkdir -p -- "$directory"
    for fan in 1 2 3; do
        printf '1000\n' > "$directory/fan${fan}_min"
        printf '4500\n' > "$directory/fan${fan}_max"
        printf 'Fan %s\n' "$fan" > "$directory/fan${fan}_label"
        if [[ $mode == hwmon ]]; then
            printf '0\n' > "$directory/fan${fan}_target"
            printf '2\n' > "$directory/pwm${fan}_enable"
        else
            printf '0\n' > "$directory/fan${fan}_output"
            printf '0\n' > "$directory/fan${fan}_manual"
        fi
    done
    "$binary" "$device" "$mode"
done
