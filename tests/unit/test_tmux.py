"""Check clipboard routing without touching the desktop clipboard."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class Tmux(unittest.TestCase):
    def test_clipboard_uses_the_attached_session_protocol(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for command in ('wl-copy', 'xclip'):
                path = root / command
                path.write_text('#!/bin/sh\nprintf "%s\\n" "${0##*/} $*" > "$COPY_LOG"\ncat >> "$COPY_LOG"\n')
                path.chmod(0o755)
            log = root / 'clipboard'
            env = {k: v for k, v in os.environ.items() if k not in ('WAYLAND_DISPLAY', 'DISPLAY')}
            env.update(PATH=str(root) + ':' + os.environ['PATH'], COPY_LOG=str(log))
            helper = ROOT / 'packages/tmux/stow/.local/bin/tmux-copy'
            for display, expected in (({'WAYLAND_DISPLAY': 'wayland-1', 'DISPLAY': ':0'}, 'wl-copy --type text/plain'),
                                      ({'DISPLAY': ':0'}, 'xclip -selection clipboard -in'), ({}, None)):
                with self.subTest(display=display):
                    log.unlink(missing_ok=True)
                    result = subprocess.run([str(helper)], input='selection\n', text=True,
                                            env={**env, **display}, capture_output=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    if expected:
                        self.assertEqual(log.read_text(), expected + '\nselection\n')
                    else:
                        self.assertFalse(log.exists())

    @unittest.skipUnless(shutil.which('tmux'), 'requires tmux')
    def test_configuration_loads_with_wayland_environment_tracking(self):
        with tempfile.TemporaryDirectory() as temporary:
            socket = str(Path(temporary) / 'tmux.socket')
            config = ROOT / 'packages/tmux/stow/.tmux.conf'
            command = ['tmux', '-S', socket]
            try:
                result = subprocess.run([*command, '-f', str(config), 'new-session', '-d', '-s', 'check', 'sleep 30'],
                                        text=True, capture_output=True)
                if result.returncode and 'Operation not permitted' in result.stderr:
                    self.skipTest('execution sandbox blocks tmux sockets')
                self.assertEqual(result.returncode, 0, result.stderr)
                environment = subprocess.check_output([*command, 'show-options', '-gv', 'update-environment'], text=True)
                self.assertIn('WAYLAND_DISPLAY', environment)
                self.assertIn('XDG_RUNTIME_DIR', environment)
                bindings = subprocess.check_output([*command, 'list-keys', '-T', 'copy-mode-vi'], text=True)
                self.assertIn('tmux-copy', bindings)
            finally:
                subprocess.run([*command, 'kill-server'], capture_output=True)
