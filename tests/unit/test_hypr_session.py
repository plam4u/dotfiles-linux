"""Verify login terminal setup against an isolated tmux server."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


@unittest.skipUnless(shutil.which('tmux'), 'tmux is required')
class HyprSession(unittest.TestCase):
    def test_new_session_and_existing_session_preservation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            socket = str(root / 'socket')
            real_tmux = shutil.which('tmux')
            wrapper = root / 'tmux'
            wrapper.write_text('#!/bin/sh\nexec "$REAL_TMUX" -S "$TEST_SOCKET" -f /dev/null "$@"\n')
            wrapper.chmod(0o755)
            foot = root / 'foot'
            foot.write_text('#!/bin/sh\nexit 0\n')
            foot.chmod(0o755)
            env = {**os.environ, 'HOME': str(root), 'REAL_TMUX': real_tmux,
                   'TEST_SOCKET': socket, 'PATH': str(root) + ':' + os.environ['PATH']}
            launcher = ROOT / 'packages/hypr/stow/.local/bin/hypr-main-terminal'
            def tmux(*args):
                return subprocess.check_output([real_tmux, '-S', socket, *args], text=True).strip()
            try:
                subprocess.run([str(launcher)], env=env, check=True)
                self.assertEqual(tmux('list-windows', '-t', 'main', '-F', '#{window_name}'),
                                 'code\nshell\ndotfiles')
                self.assertEqual(tmux('display-message', '-p', '-t', 'main:dotfiles', '#{pane_current_path}'), str(ROOT))
                tmux('new-window', '-t', 'main', '-n', 'extra')
                subprocess.run([str(launcher)], env=env, check=True)
                self.assertEqual(tmux('list-windows', '-t', 'main', '-F', '#{window_name}'),
                                 'code\nshell\ndotfiles\nextra')
            finally:
                subprocess.run([real_tmux, '-S', socket, 'kill-server'], capture_output=True)
