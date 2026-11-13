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
            (defaults / 'rc').write_text('source "$OMARCHY_PATH/default/bash/functions"\n')
            (defaults / 'functions').write_text('omarchy_test_function() { printf omarchy; }\nga() { :; }\ngd() { :; }\n')
            (defaults / 'envs').write_text('export OMARCHY_TEST_ENV=yes\n')
            (defaults / 'shell').write_text('')
            (defaults / 'aliases').write_text('alias omarchy_test_alias=true\nalias t=tmux\n')
            (defaults / 'init').write_text('')
            (defaults / 'inputrc').write_text('')
            rc = home / '.bashrc'
            rc.write_text((ROOT / 'packages/shell/stow/.bashrc').read_text().replace(
                '/usr/share/omarchy/default/bash/env-bootstrap', str(bootstrap)))
            fragments = home / '.bashrc.d'
            fragments.mkdir()
            (fragments / '00-shell.sh').symlink_to(ROOT / 'packages/shell/stow/.bashrc.d/00-shell.sh')
            (fragments / 'tig.sh').symlink_to(ROOT / 'packages/tig/stow/.bashrc.d/tig.sh')
            (fragments / 'git.sh').write_text("alias ga='git add'\nalias gd='git diff'\n")
            (home / '.bash_aliases').write_text('alias omarchy_test_alias=false\n')
            env = {**os.environ, 'HOME': str(home), 'TERM': 'dumb'}
            result = subprocess.run(['bash', '--noprofile', '--norc', '-c',
                                     '. "$HOME/.bashrc"; test "$OMARCHY_ENV_LOADED" = yes'],
                                    env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            result = subprocess.run(['bash', '--noprofile', '--norc', '-ic', '''
ga() { :; }
gd() { :; }
. "$HOME/.bashrc"
first_path=$PATH
. "$HOME/.bashrc"
test "$PATH" = "$first_path" || exit 1
test "$DOTFILES_ROOT" = "$EXPECTED_ROOT" || exit 1
test "$OMARCHY_TEST_ENV" = yes || exit 1
if declare -F omarchy_test_function ga gd; then exit 1; fi
alias ga gd
alias omarchy_test_alias
alias t
'''], env={**env, 'EXPECTED_ROOT': str(ROOT)}, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn('syntax error', result.stderr)
            self.assertIn("ga='git add'", result.stdout)
            self.assertIn("gd='git diff'", result.stdout)
            self.assertIn("omarchy_test_alias='false'", result.stdout)
            self.assertIn("t='tig'", result.stdout)
