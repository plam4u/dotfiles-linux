"""Exercise uninstall with real Stow and isolated, mocked package managers."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


@unittest.skipIf(os.geteuid() == 0, 'pm requires a regular user')
class Uninstall(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.repo = self.root / 'repo'
        self.home = self.root / 'home'
        self.mock_bin = self.root / 'mock-bin'
        for path in (self.repo / 'bin', self.repo / 'packages', self.repo / 'bundles', self.home, self.mock_bin):
            path.mkdir(parents=True)
        self.release = self.root / 'os-release'
        self.release.write_text('ID=debian\n')
        # Supply a release file without changing the command's distro selection logic.
        (self.repo / 'bin/pm').write_text((ROOT / 'bin/pm').read_text().replace('/etc/os-release', str(self.release)))
        self.log = self.root / 'commands'
        self.env = {**os.environ, 'HOME': str(self.home),
                    'PATH': str(self.mock_bin) + ':' + os.environ['PATH'],
                    'PM_TEST_LOG': str(self.log)}
        self.mock('sudo', 'exec "$@"')
        self.mock('apt-get', 'printf "apt-get %s\\n" "$*" >> "$PM_TEST_LOG"\nexit "${PM_TEST_FAIL:-0}"')
        self.mock('dpkg-query', '[[ ${@: -1} != absent ]] || exit 1\nprintf installed')
        self.mock('pacman', '''
case $1 in
    -Q) [[ ${@: -1} != absent && ${@: -1} != desktop-group ]] ;;
    -Qg) [[ ${@: -1} == desktop-group ]] ;;
    -R) printf 'pacman %s\\n' "$*" >> "$PM_TEST_LOG" ;;
    *) exit 99 ;;
esac
''')
        self.mock('flatpak', '''
case $1 in
    info) [[ ${@: -1} != absent ]] ;;
    uninstall) printf 'flatpak %s\\n' "$*" >> "$PM_TEST_LOG" ;;
    *) exit 99 ;;
esac
''')

    def mock(self, name, body):
        path = self.mock_bin / name
        path.write_text('#!/usr/bin/env bash\nset -eu\n' + body + '\n')
        path.chmod(0o755)

    def package(self, name, rows='', script=None, config=False):
        path = self.repo / 'packages' / name
        path.mkdir()
        (path / 'install.tsv').write_text('# distro\tinstaller\ttarget\n' + rows)
        if '\tscript\t' in rows:
            (path / 'install.sh').write_text('exit 99\n')
        if script is not None:
            (path / 'uninstall.sh').write_text(script)
        if config:
            (path / 'stow').mkdir()
            (path / 'stow' / ('.' + name)).write_text('managed')
        return path

    def pm(self, *args, succeeds=True):
        result = subprocess.run(['bash', str(self.repo / 'bin/pm'), *args],
                                env=self.env, text=True, capture_output=True)
        if succeeds:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def commands(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_light_locker_install_dry_run_remove_and_repeat(self):
        shutil.copytree(ROOT / 'packages/disable-light-locker', self.repo / 'packages/disable-light-locker')
        target = self.home / '.config/autostart/light-locker.desktop'
        target.parent.mkdir(parents=True)
        target.write_text('original override')
        self.pm('install', 'disable-light-locker')
        self.assertTrue(target.is_symlink())
        self.assertIn('Hidden=true', target.read_text())
        self.pm('uninstall', '--dry-run', 'disable-light-locker')
        self.assertTrue(target.is_symlink())
        # Ignore user Stow options that could change deletion into installation.
        (self.home / '.stowrc').write_text('--stow\n')
        self.pm('uninstall', 'disable-light-locker')
        self.assertFalse(target.is_symlink())
        self.assertFalse(target.exists())
        self.assertEqual(target.with_suffix('.desktop.bak').read_text(), 'original override')
        self.pm('uninstall', 'disable-light-locker')
        self.assertEqual(self.commands(), [])

    def test_unstow_preserves_replacement_file_and_unrelated_symlink(self):
        self.package('example', config=True)
        target = self.home / '.example'
        target.write_text('private')
        self.pm('uninstall', 'example')
        self.assertEqual(target.read_text(), 'private')
        target.unlink()
        unrelated = self.home / 'private'
        unrelated.write_text('private')
        target.symlink_to(unrelated)
        self.pm('uninstall', 'example')
        self.assertEqual(target.resolve(), unrelated)

    def test_native_backends_skip_absent_and_use_matching_rows(self):
        for distro, installer, command in (('debian', 'apt', 'apt-get remove -y -- present'),
                                            ('arch', 'pacman', 'pacman -R --noconfirm -- present')):
            with self.subTest(distro=distro):
                self.release.write_text('ID=' + distro + '\n')
                name = 'native-' + distro
                self.package(name, f'{distro}\t{installer}\tpresent\t{os.uname().machine}\n{distro}\t{installer}\tabsent\n'
                             + f'{distro}\t{installer}\twrong-architecture\tunsupported_arch\n')
                self.pm('uninstall', name)
                self.assertEqual(self.commands()[-1], command)
        self.assertEqual(len(self.commands()), 2)
        self.package('group', 'arch\tpacman\tdesktop-group\n')
        self.pm('uninstall', 'group')
        self.assertEqual(self.commands()[-1], 'pacman -R --noconfirm -- desktop-group')

    def test_system_flatpak_and_optional_script(self):
        self.package('mixed', 'debian\tapt\tpresent\ndebian\tflatpak\torg.example.App\n'
                     'debian\tflatpak\tabsent\ndebian\tscript\tinstall.sh\n', config=True)
        self.pm('stow', 'mixed')
        result = self.pm('uninstall', 'mixed')
        self.assertIn('Warning: mixed: missing uninstall.sh', result.stderr)
        self.assertFalse((self.home / '.mixed').exists())
        self.assertEqual(self.commands(), ['flatpak uninstall --system --noninteractive org.example.App',
                                          'apt-get remove -y -- present'])

    def test_dry_run_never_executes_removals_or_scripts(self):
        self.package('example', 'debian\tapt\tpresent\ndebian\tscript\tinstall.sh\n',
                     script='exit 99\n', config=True)
        self.pm('stow', 'example')
        result = self.pm('uninstall', '--dry-run', 'example')
        self.assertIn('uninstall.sh', result.stdout)
        self.assertIn('apt-get remove', result.stdout)
        self.assertTrue((self.home / '.example').is_symlink())
        self.assertEqual(self.commands(), [])

    def test_reverse_bundle_order_and_scripts_before_dependencies(self):
        for name in ('one', 'two'):
            self.package(name, f'debian\tapt\t{name}\ndebian\tscript\tinstall.sh\n',
                         script='[[ ! -e "$HOME/.one" && ! -e "$HOME/.two" ]] || exit 99\n'
                         + f'printf "script {name}\\n" >> "$PM_TEST_LOG"\n', config=True)
        (self.repo / 'bundles/example').write_text('one\ntwo\n')
        self.pm('stow', '--bundle', 'example')
        self.pm('uninstall', '--bundle', 'example')
        self.assertEqual(self.commands(), ['script two', 'apt-get remove -y -- two',
                                          'script one', 'apt-get remove -y -- one'])

    def test_validation_and_real_failures_stop_removal(self):
        self.package('example', 'debian\tapt\tpresent\ndebian\tscript\tinstall.sh\n',
                     script='exit 23\n', config=True)
        self.pm('stow', 'example')
        self.pm('uninstall', 'example', 'unknown', succeeds=False)
        self.assertTrue((self.home / '.example').is_symlink())
        self.pm('uninstall', 'example', succeeds=False)
        self.assertEqual(self.commands(), [])
        # No attempt to reinstall configs after the failing script.
        self.assertFalse((self.home / '.example').exists())
        self.package('native', 'debian\tapt\tfirst\ndebian\tapt\tsecond\n')
        self.env['PM_TEST_FAIL'] = '42'
        self.pm('uninstall', 'native', succeeds=False)
        self.assertEqual(self.commands(), ['apt-get remove -y -- second'])

    def test_hardware_check_does_not_block_uninstall(self):
        package = self.package('hardware', 'debian\tscript\tinstall.sh\n',
                               script='printf "hardware\\n" >> "$PM_TEST_LOG"\n')
        (package / 'hardware-model').write_text('not-this-machine\n')
        self.pm('uninstall', 'hardware')
        self.assertEqual(self.commands(), ['hardware'])


class ScriptUninstall(unittest.TestCase):
    def test_user_installers_remove_programs_and_keep_app_data(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            files = ('.local/bin/cliamp', '.local/bin/yt-dlp', '.deno/bin/deno',
                     '.local/share/bash-completion/completions/deno.bash', '.zsh/completions/_deno',
                     '.oh-my-bash/oh-my-bash.sh')
            for relative in files:
                target = home / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text('installed')
            data = home / '.deno/cache/keep'
            data.parent.mkdir(parents=True)
            data.write_text('user data')
            for name in ('cliamp', 'yt-dlp', 'deno', 'oh-my-bash'):
                for _ in range(2):
                    result = subprocess.run(['bash', str(ROOT / 'packages' / name / 'uninstall.sh')],
                                            env={**os.environ, 'HOME': directory}, capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(all(not (home / relative).exists() for relative in files))
            self.assertEqual(data.read_text(), 'user data')

    def test_neovim_only_removes_its_own_link_and_prefix(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            prefix = home / '.local/opt/neovim-c868e1ab3d11ac2a0cc3c284b16808f3de5adf31'
            (prefix / 'bin').mkdir(parents=True)
            (prefix / 'bin/nvim').write_text('installed')
            link = home / '.local/bin/nvim'
            link.parent.mkdir()
            link.symlink_to(prefix / 'bin/nvim')
            def uninstall():
                result = subprocess.run(['bash', str(ROOT / 'packages/neovim-nightly/uninstall.sh')],
                                        env={**os.environ, 'HOME': directory}, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
            uninstall()
            self.assertFalse(link.is_symlink())
            self.assertFalse(prefix.exists())
            unrelated = home / 'another-nvim'
            unrelated.write_text('private')
            link.symlink_to(unrelated)
            uninstall()
            self.assertEqual(link.resolve(), unrelated)
            self.assertEqual(unrelated.read_text(), 'private')

    def test_system_config_helper_preserves_changes_and_symlinks(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            reference = root / 'reference'
            target = root / 'target'
            reference.write_text('managed')
            setup = '. "$1"\nsudo() { "$@"; }\nremove_matching_file "$2" "$3"\n'
            def uninstall():
                result = subprocess.run(['bash', '-eu', '-c', setup, 'test',
                                         str(ROOT / 'share/uninstall.sh'), str(reference), str(target)],
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
            target.write_text('managed')
            uninstall()
            self.assertFalse(target.exists())
            target.write_text('private')
            uninstall()
            self.assertEqual(target.read_text(), 'private')
            target.unlink()
            target.symlink_to(reference)
            uninstall()
            self.assertTrue(target.is_symlink())


if __name__ == '__main__':
    unittest.main()
