"""Check local fan-package installation and activation without host changes."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class Mbpfan(unittest.TestCase):
    def test_build_once_activate_and_stop_before_removal(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            package = root / 'packages/mbpfan'
            shutil.copytree(ROOT / 'packages/mbpfan', package)
            shutil.copytree(ROOT / 'share', root / 'share')
            release = root / 'os-release'
            release.write_text('ID=omarchy\n')
            for script in root.rglob('*.sh'):
                script.write_text(script.read_text().replace('/etc/os-release', str(release)))
            mock_bin = root / 'bin'
            mock_bin.mkdir()
            mocks = {
                'sudo': 'exec "$@"',
                'vercmp': 'printf \"%s\\n\" \"${FAN_COMPARE:-0}\"',
                'makepkg': '''
if [ "${1:-}" = --packagelist ]; then
    printf '%s/mbpfan.pkg.tar.zst\n' "$PWD"
else
    printf 'makepkg\n' >> "$FAN_LOG"
    touch mbpfan.pkg.tar.zst
fi
''',
                'pacman': '''
case $1 in
    -Q|-Qg) test -f "$FAN_INSTALLED" || exit 1; printf "mbpfan 2.4.0-2\n" ;;
    -U) printf 'install\n' >> "$FAN_LOG"; touch "$FAN_INSTALLED" ;;
    -R) printf 'remove\n' >> "$FAN_LOG"; rm "$FAN_INSTALLED" ;;
esac
''',
                'modprobe': 'printf "modprobe %s\\n" "$*" >> "$FAN_LOG"',
                'systemctl': '''
if [ "$1" != cat ]; then printf 'systemctl %s\n' "$*" >> "$FAN_LOG"; fi
''',
            }
            for name, body in mocks.items():
                path = mock_bin / name
                path.write_text('#!/bin/sh\nset -eu\n' + body + '\n')
                path.chmod(0o755)
            log = root / 'commands'
            env = {**os.environ, 'PATH': str(mock_bin) + ':' + os.environ['PATH'],
                   'FAN_LOG': str(log), 'FAN_INSTALLED': str(root / 'installed')}
            for _ in range(2):
                for script in ('arch.sh', 'install.sh'):
                    result = subprocess.run(['bash', str(package / script)], env=env, text=True, capture_output=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
            commands = log.read_text().splitlines()
            self.assertEqual(commands.count('makepkg'), 1)
            self.assertLess(commands.index('install'), commands.index('modprobe applesmc'))
            self.assertLess(commands.index('modprobe coretemp'), commands.index('systemctl restart mbpfan.service'))
            self.assertEqual(commands.count('systemctl restart mbpfan.service'), 2)
            # Upgrading an existing older package must rebuild and restart it.
            older_env = {**env, 'FAN_COMPARE': '-1'}
            for script in ('arch.sh', 'install.sh'):
                result = subprocess.run(['bash', str(package / script)], env=older_env, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
            commands = log.read_text().splitlines()
            self.assertEqual(commands.count('makepkg'), 2)
            self.assertEqual(commands.count('systemctl restart mbpfan.service'), 3)
            result = subprocess.run(['bash', str(package / 'uninstall.sh')], env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            commands = log.read_text().splitlines()
            self.assertLess(commands.index('systemctl disable --now mbpfan.service'), commands.index('remove'))
