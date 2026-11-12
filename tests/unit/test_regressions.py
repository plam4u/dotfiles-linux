"""Run with python3 -B -m unittest discover -s tests/unit -v."""
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('sources', ROOT / 'packages/debian-apt/sources.py')
sources = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sources)
PM_FUNCTIONS = (ROOT / 'bin/pm').read_text().split('case ${1:-} in')[0]


class Regressions(unittest.TestCase):
    def bash(self, script, **kwargs):
        return subprocess.run(['bash', '-c', script], text=True, capture_output=True, **kwargs)

    def test_architecture_coverage(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'test.sources'
            path.write_text('Types: deb deb-src\nURIs: https://deb.debian.org/debian\n'
                            'Suites: trixie\nComponents: main contrib non-free non-free-firmware\n'
                            'Architectures: amd64\n')
            existing = list(sources.read_sources(path, ('amd64', 'i386')))
            additions = list(sources.missing_sources(existing, ('amd64', 'i386')))
            trixie = [s for s in additions if 'Suites: trixie\n' in s]
            self.assertEqual(len(trixie), 1)
            self.assertIn('Architectures: i386\n', trixie[0])
            # The generated entries fill all gaps on the second pass.
            path.write_text('\n'.join(additions))
            existing += list(sources.read_sources(path, ('amd64', 'i386')))
            self.assertEqual(list(sources.missing_sources(existing, ('amd64', 'i386'))), [])

    def test_architecture_options_both_formats(self):
        with tempfile.TemporaryDirectory() as directory:
            for suffix, content in (
                ('list', 'deb [arch=amd64 arch+=arm64 arch-=amd64] https://deb.debian.org/debian trixie main\n'),
                ('sources', 'Types: deb\nURIs: https://deb.debian.org/debian\nSuites: trixie\nComponents: main\nArchitectures: amd64\nArchitectures-Add: arm64\nArchitectures-Remove: amd64\n'),
            ):
                path = Path(directory) / ('test.' + suffix)
                path.write_text(content)
                self.assertEqual(list(sources.read_sources(path))[0].architectures, {'arm64'})

    def test_bundle_order_and_cycle(self):
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            (repo / 'bundles').mkdir()
            (repo / 'bundles/a').write_text('one\n@b\nthree\n')
            (repo / 'bundles/b').write_text('two\none\n')
            setup = PM_FUNCTIONS + '\ndeclare -A requested=() active_bundles=()\npackages=()\nrepo=$1\n'
            result = subprocess.run(['bash', '-c', setup + 'read_bundle a\nprintf "%s\\n" "${packages[@]}"', 'test', str(repo)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines(), ['one', 'two', 'three'])
            (repo / 'bundles/b').write_text('@a\n')
            result = subprocess.run(['bash', '-c', setup + 'read_bundle a', 'test', str(repo)], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('bundle include cycle', result.stderr)

    def test_stow_backup_repeat_and_rollback(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            home = root / 'home'
            package = root / 'package'
            home.mkdir()
            (package / 'stow').mkdir(parents=True)
            (package / 'stow/.example').write_text('tracked')
            target = home / '.example'
            target.write_text('original')
            (home / '.example.bak').write_text('older')
            setup = PM_FUNCTIONS + '\npackage_dir=$1\nstow_package apply\n'
            def run(script):
                return subprocess.run(['bash', '-c', script, 'test', str(package)], env={**os.environ, 'HOME': str(home)}, capture_output=True, text=True)
            result = run(setup)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(target.is_symlink())
            self.assertEqual((home / '.example.bak.1').read_text(), 'original')
            self.assertEqual(run(setup).returncode, 0)
            target.unlink()
            target.write_text('restore me')
            # Fail only the real linking step, letting real Stow identify conflicts.
            failure = PM_FUNCTIONS + '\n' + '''
stow_command() {
    if [[ ${1:-} == --simulate ]]; then
        (cd /; HOME=/dev/null LC_ALL=C stow --dir="$package_dir" --target="$target_home" --no-folding "$@" --stow stow)
    else
        return 1
    fi
}
package_dir=$1
stow_package apply
'''
            result = run(failure)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(target.read_text(), 'restore me')
            self.assertFalse((home / '.example.bak.2').exists())

    def test_custom_config_rejected_before_changes(self):
        for package in ('xfce4', 'xfce4-terminal'):
            result = subprocess.run(['bash', str(ROOT / 'packages' / package / 'post-install.sh')], env={**os.environ, 'XDG_CONFIG_HOME': '/tmp/custom-config'}, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('requires XDG_CONFIG_HOME', result.stderr)

    def test_package_shell_fragments(self):
        for shell in ('bash', 'zsh'):
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as directory:
                home = Path(directory)
                env = {k: v for k, v in os.environ.items() if k not in ('EDITOR', 'VISUAL')}
                env.update(HOME=directory, PATH='/usr/bin:/bin', TERM='xterm')

                def stow(package, delete=False):
                    result = subprocess.run(['stow', '--no-folding',
                                             '--dir=' + str(ROOT / 'packages' / package),
                                             '--target=' + directory,
                                             '--delete' if delete else '--stow', 'stow'],
                                            env=env, capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, result.stderr)

                def run(script):
                    flags = ['--noprofile', '--norc'] if shell == 'bash' else ['-f']
                    return subprocess.run([shell, *flags, '-i', '-c', script],
                                          env=env, capture_output=True, text=True)

                stow('shell')
                # Generic startup works without Deno or its fragments installed.
                startup = '. "$HOME/.' + shell + 'rc"; '
                result = run(startup + 'printf "%s|%s|%s" "$EDITOR" "$VISUAL" "$PATH"')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn('vim|vim|', result.stdout)
                self.assertNotIn(str(home / '.deno/bin'), result.stdout)

                binary = home / '.deno/bin/deno'
                binary.parent.mkdir(parents=True)
                binary.write_text('#!/bin/sh\nexit 0\n')
                binary.chmod(0o755)
                completion = home / '.local/share/bash-completion/completions/deno.bash'
                completion.parent.mkdir(parents=True)
                completion.write_text('DENO_COMPLETION_LOADED=yes\n')
                (home / '.zsh/completions').mkdir(parents=True)
                stow('deno')
                result = run(startup + 'first_path=$PATH; ' + startup +
                             '[ "$PATH" = "$first_path" ] || exit 1; '
                             'command -v deno; alias ll; ' +
                             ('[ "$DENO_COMPLETION_LOADED" = yes ]' if shell == 'bash' else
                              '[[ ":$FPATH:" == *":$HOME/.zsh/completions:"* ]]'))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(str(binary), result.stdout)
                self.assertIn('ls -l', result.stdout)
                env.update(EDITOR='nano', VISUAL='code --wait')
                result = run(startup + 'printf "%s|%s" "$EDITOR" "$VISUAL"')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn('nano|code --wait', result.stdout)
                stow('deno', delete=True)
                result = run(startup + 'printf "%s" "$PATH"')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertNotIn(str(binary.parent), result.stdout)

                # Login environment remains available without interactive settings.
                for login_shell in ('sh', 'bash'):
                    result = subprocess.run([login_shell, '-c',
                                             '. "$HOME/.profile"; printf "%s|%s" "$EDITOR" "$PATH"'],
                                            env=env, capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertIn('nano|', result.stdout)
                    self.assertIn(str(ROOT / 'bin'), result.stdout)


if __name__ == '__main__':
    unittest.main()
