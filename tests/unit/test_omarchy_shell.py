"""Check Omarchy initialization survives the saved Bash startup."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class OmarchyShell(unittest.TestCase):
    def test_environment_and_interactive_defaults_survive_repeated_sourcing(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            defaults = home / 'omarchy/default/bash'
            defaults.mkdir(parents=True)
            bootstrap = defaults / 'env-bootstrap'
            bootstrap.write_text('export OMARCHY_PATH="$HOME/omarchy"\nexport OMARCHY_ENV_LOADED=yes\n')
            (defaults / 'rc').write_text('omarchy_test_function() { printf omarchy; }\nalias omarchy_test_alias=true\n')
            rc = home / '.bashrc'
            rc.write_text((ROOT / 'packages/shell/stow/.bashrc').read_text().replace(
                '/usr/share/omarchy/default/bash/env-bootstrap', str(bootstrap)))
            fragments = home / '.bashrc.d'
            fragments.mkdir()
            (fragments / '00-shell.sh').symlink_to(ROOT / 'packages/shell/stow/.bashrc.d/00-shell.sh')
            (home / '.bash_aliases').write_text('alias omarchy_test_alias=false\n')
            env = {**os.environ, 'HOME': str(home), 'TERM': 'dumb'}
            result = subprocess.run(['bash', '--noprofile', '--norc', '-c',
                                     '. "$HOME/.bashrc"; test "$OMARCHY_ENV_LOADED" = yes'],
                                    env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            result = subprocess.run(['bash', '--noprofile', '--norc', '-ic', '''
. "$HOME/.bashrc"
first_path=$PATH
. "$HOME/.bashrc"
test "$PATH" = "$first_path" || exit 1
test "$DOTFILES_ROOT" = "$EXPECTED_ROOT" || exit 1
omarchy_test_function
alias omarchy_test_alias
'''], env={**env, 'EXPECTED_ROOT': str(ROOT)}, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('omarchy', result.stdout)
            self.assertIn("omarchy_test_alias='false'", result.stdout)
