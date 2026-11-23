#!/usr/bin/env bash
set -euo pipefail

systemctl --user daemon-reload
systemctl --user enable --now gcr-ssh-agent.socket
systemctl --user set-environment "SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gcr/ssh"
printf 'SSH agent enabled. Log out and back in so all applications use it.\n'
printf 'The first use of an encrypted key prompts for its passphrase graphically.\n'
