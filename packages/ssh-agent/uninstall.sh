#!/usr/bin/env bash
set -euo pipefail

systemctl --user disable --now gcr-ssh-agent.socket
systemctl --user stop gcr-ssh-agent.service
systemctl --user unset-environment SSH_AUTH_SOCK
printf 'SSH agent disabled. Log out and back in to refresh application environments.\n'
