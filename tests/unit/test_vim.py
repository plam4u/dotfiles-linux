"""Exercise real Vim yanks with mocked desktop clipboard commands."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


@unittest.skipUnless(shutil.which('vim'), 'Vim is required')
class VimClipboard(unittest.TestCase):
    def test_yanks_follow_display_protocol(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            helper = root / '.local/bin/vim-copy'
            helper.parent.mkdir(parents=True)
            helper.symlink_to(ROOT / 'packages/vim/stow/.local/bin/vim-copy')
            for command in ('wl-copy', 'xclip'):
                mock = root / command
                mock.write_text('#!/bin/sh\nprintf "%s %s\\n" "${0##*/}" "$*" >> "$COPY_LOG"\ncat > "$COPY_TEXT"\n')
                mock.chmod(0o755)
            log, copied = root / 'log', root / 'text'
            script = root / 'test.vim'
            config = ROOT / 'packages/vim/stow/.vimrc'
            script.write_text(f'source {config}\nsource {config}\n'
                              "call setline(1, ['hello clipboard', 'second line'])\n"
                              'normal gg0Vy\n'
                              'normal! "ayy\n'
                              'normal! dd\nqa!\n')
            for display, expected in (
                ({'WAYLAND_DISPLAY': 'wayland-1', 'DISPLAY': ':0'}, 'wl-copy --type text/plain'),
                ({'DISPLAY': ':0'}, 'xclip -selection clipboard -in'),
                ({}, None),
            ):
                with self.subTest(display=display):
                    log.unlink(missing_ok=True)
                    copied.unlink(missing_ok=True)
                    env = {k: v for k, v in os.environ.items()
                           if k not in ('WAYLAND_DISPLAY', 'DISPLAY')}
                    env.update(display, HOME=str(root), PATH=str(root) + ':' + os.environ['PATH'],
                               COPY_LOG=str(log), COPY_TEXT=str(copied))
                    result = subprocess.run(['vim', '-Nu', 'NONE', '-n', '-es', '-S', str(script)],
                                            env=env, capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    if expected:
                        self.assertEqual(log.read_text().splitlines(), [expected])
                        self.assertEqual(copied.read_text(), 'hello clipboard\n')
                    else:
                        self.assertFalse(log.exists())
