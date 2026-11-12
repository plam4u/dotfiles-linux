"""Apply keyboard layout overrides to a temporary Omarchy input file."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class HyprlandKeyboard(unittest.TestCase):
    def test_install_preserves_input_repeats_and_checks_reload(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = root / 'config/hypr'
            config.mkdir(parents=True)
            input_file = config / 'input.lua'
            original = '-- Personal input settings\nhl.config({ input = { sensitivity = 0.2 } })\n'
            input_file.write_text(original)
            release = root / 'os-release'
            release.write_text('ID=omarchy\n')
            script = root / 'hyprland.sh'
            script.write_text((ROOT / 'packages/system-preferences/hyprland.sh').read_text().replace('/etc/os-release', str(release)))
            mock = root / 'bin'
            mock.mkdir()
            hyprctl = mock / 'hyprctl'
            hyprctl.write_text('''#!/bin/sh
printf '%s\n' "$*" >> "$HYPR_TEST_LOG"
if [ "$1" = configerrors ]; then printf '%s' "${HYPR_TEST_ERRORS:-}"; fi
''')
            hyprctl.chmod(0o755)
            log = root / 'commands'
            env = {**os.environ, 'XDG_CONFIG_HOME': str(root / 'config'), 'PATH': str(mock) + ':' + os.environ['PATH'],
                   'HYPR_TEST_LOG': str(log), 'HYPRLAND_INSTANCE_SIGNATURE': 'test'}
            for _ in range(2):
                result = subprocess.run(['bash', str(script)], env=env, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(input_file.read_text().startswith(original))
            self.assertEqual(input_file.read_text().count('kb_variant = "altgr-intl"'), 1)
            self.assertEqual(Path(str(input_file) + '.~1~').read_text(), original)
            self.assertFalse(Path(str(input_file) + '.~2~').exists())
            self.assertEqual(log.read_text().splitlines(), ['reload', 'configerrors'] * 2)
            result = subprocess.run(['bash', str(script)], env={**env, 'HYPR_TEST_ERRORS': 'invalid setting'},
                                    text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('invalid setting', result.stderr)
