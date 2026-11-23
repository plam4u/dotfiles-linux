"""Verify SSH agent lifecycle without changing the host session."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class SshAgent(unittest.TestCase):
    def test_socket_activation_and_shutdown(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            log = root / 'commands'
            mock = root / 'systemctl'
            mock.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$AGENT_TEST_LOG"\n')
            mock.chmod(0o755)
            env = {**os.environ, 'PATH': str(root) + ':' + os.environ['PATH'],
                   'AGENT_TEST_LOG': str(log), 'XDG_RUNTIME_DIR': str(root)}
            for script in ('install.sh', 'uninstall.sh'):
                subprocess.run(['bash', str(ROOT / 'packages/ssh-agent' / script)],
                               env=env, check=True, capture_output=True)
            self.assertEqual(log.read_text().splitlines(), [
                '--user daemon-reload',
                '--user enable --now gcr-ssh-agent.socket',
                f'--user set-environment SSH_AUTH_SOCK={root}/gcr/ssh',
                '--user disable --now gcr-ssh-agent.socket',
                '--user stop gcr-ssh-agent.service',
                '--user unset-environment SSH_AUTH_SOCK',
            ])
