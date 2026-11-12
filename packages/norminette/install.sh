#!/usr/bin/env bash
set -euo pipefail

pipx install norminette
pipx ensurepath
printf 'Norminette is installed. Open a new terminal if norminette is not yet on PATH.\n'
