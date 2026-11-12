"""Exercise Samba setup and bootstrap restore instructions."""
import os
from pathlib import Path
import shutil
import shlex
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


@unittest.skipIf(os.geteuid() == 0, 'setup scripts require a regular user')
class PackageSettings(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='pm settings & ')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.repo = self.root / 'repo'
        self.home = self.root / 'home'
        self.home.mkdir()
        self.mock_bin = self.root / 'bin'
        self.mock_bin.mkdir()
        self.log = self.root / 'commands'
        shutil.copytree(ROOT / 'packages/samba', self.repo / 'packages/samba')
        self.env = dict(os.environ)
        self.env.update(HOME=str(self.home),
                        PATH=str(self.mock_bin) + ':' + os.environ['PATH'],
                        SETTINGS_TEST_LOG=str(self.log))
        self.mock('sudo', '''
import subprocess
import sys
args = sys.argv[1:]
if args[0] == 'install':
    for option in ('-o', '-g'):
        index = args.index(option)
        del args[index:index + 2]
sys.exit(subprocess.run(args).returncode)
''')
        self.mock('systemctl', '''
import os
from pathlib import Path
import sys
if sys.argv[1] == 'is-active':
    sys.exit(0 if sys.argv[-1] == 'smbd.service' else 3)
with Path(os.environ['SETTINGS_TEST_LOG']).open('a') as log:
    log.write(' '.join(sys.argv[1:]) + '\\n')
''')

    def mock(self, name, code):
        path = self.mock_bin / name
        path.write_text('#!' + sys.executable + '\n' + code)
        path.chmod(0o755)

    def run_command(self, *args):
        result = subprocess.run(args, env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    @unittest.skipUnless(shutil.which('testparm'), 'requires Samba testparm')
    def test_samba_config_renders_validates_and_preserves_backups(self):
        package = self.repo / 'packages/samba'
        script = package / 'install.sh'
        destination = self.root / 'etc/samba/smb.conf'
        destination.parent.mkdir(parents=True)
        destination.write_text('previous config')
        script.write_text(script.read_text().replace('/etc/samba/smb.conf', shlex.quote(str(destination))))
        self.run_command('bash', str(script))
        username = subprocess.check_output(['id', '-un'], text=True).strip()
        config = destination.read_text()
        self.assertIn(f'path = {self.home}/Public', config)
        self.assertIn(f'valid users = {username}', config)
        self.assertNotIn('@HOME@', config)
        self.assertEqual(destination.with_name('smb.conf.~1~').read_text(), 'previous config')
        self.assertTrue((self.home / 'Public').is_dir())
        self.assertEqual(self.log.read_text(), 'reload smbd.service\n')
        self.run_command('bash', str(script))
        self.assertFalse(destination.with_name('smb.conf.~2~').exists())
        self.run_command('bash', str(package / 'uninstall.sh'))
        self.assertEqual(destination.read_text(), config)

    def test_bootstrap_links_restore_guide_without_package_checklists(self):
        script = self.repo / 'bootstrap.sh'
        release = self.root / 'os-release'
        script.write_text((ROOT / 'bootstrap.sh').read_text().replace('/etc/os-release', shlex.quote(str(release))))
        (self.repo / 'bin').mkdir()
        pm = self.repo / 'bin/pm'
        pm.write_text('#!/usr/bin/env bash\nexit 0\n')
        pm.chmod(0o755)
        for distro in ('debian', 'arch'):
            with self.subTest(distro=distro):
                release.write_text(f'ID={distro}\nVERSION_CODENAME=trixie\n')
                result = self.run_command('bash', str(script))
                for text in ('setup is not complete', 'packages/restic/README.md'):
                    self.assertIn(text, result.stdout)
                for text in ('Samba', 'smbpasswd', 'restic -r', '~/.ssh', '/etc/ssh'):
                    self.assertNotIn(text, result.stdout)


if __name__ == '__main__':
    unittest.main()
