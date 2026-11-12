#!/usr/bin/env bash
set -euo pipefail

rm -fv -- "$HOME/.local/bin/cliamp"
if [[ -x /usr/local/bin/cliamp ]]; then
    printf 'Keeping /usr/local/bin/cliamp, which this package does not install.\n'
fi
