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
        self.release = self.root / 'os-release'
        self.release.write_text('ID=debian\n')
        for name in ('install.sh', 'uninstall.sh'):
            script = self.repo / 'packages/samba' / name
            script.write_text(script.read_text().replace('/etc/os-release', shlex.quote(str(self.release))))
        self.env = dict(os.environ)
        self.env.update(HOME=str(self.home),
                        PATH=str(self.mock_bin) + ':' + os.environ['PATH'],
                        SETTINGS_TEST_LOG=str(self.log), SAMBA_TEST_ACCOUNT=str(self.root / 'samba-account'))
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
if sys.argv[1] == 'cat':
    sys.exit(0)
with Path(os.environ['SETTINGS_TEST_LOG']).open('a') as log:
    log.write(' '.join(sys.argv[1:]) + '\\n')
''')
        self.mock('pdbedit', '''
import os
from pathlib import Path
import sys
if Path(os.environ['SAMBA_TEST_ACCOUNT']).exists():
    print(sys.argv[-1] + ':1000:Test User')
else:
    sys.exit(1)
''')
        self.mock('smbpasswd', '''
import os
from pathlib import Path
import sys
if os.environ.get('SAMBA_TEST_PASSWORD_FAIL'):
    sys.exit(1)
Path(os.environ['SAMBA_TEST_ACCOUNT']).touch()
with Path(os.environ['SETTINGS_TEST_LOG']).open('a') as log:
    log.write('smbpasswd ' + ' '.join(sys.argv[1:]) + '\\n')
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
        self.assertEqual(self.log.read_text(), f'smbpasswd -a {username}\nenable --now smbd.service\nreload smbd.service\n')
        self.run_command('bash', str(script))
        self.assertFalse(destination.with_name('smb.conf.~2~').exists())
        self.assertEqual(self.log.read_text().count('smbpasswd'), 1)
        self.run_command('bash', str(package / 'uninstall.sh'))
        self.assertEqual(destination.read_text(), config)
        self.assertTrue(self.log.read_text().endswith('disable --now smbd.service\n'))

    @unittest.skipUnless(shutil.which('testparm'), 'requires Samba testparm')
    def test_samba_arch_activation_and_password_failure(self):
        self.release.write_text('ID=arch\n')
        script = self.repo / 'packages/samba/install.sh'
        destination = self.root / 'etc/samba/smb.conf'
        script.write_text(script.read_text().replace('/etc/samba/smb.conf', shlex.quote(str(destination))))
        self.env['SAMBA_TEST_PASSWORD_FAIL'] = '1'
        result = subprocess.run(['bash', str(script)], env=self.env, text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.log.exists())
        del self.env['SAMBA_TEST_PASSWORD_FAIL']
        self.run_command('bash', str(script))
        self.assertIn('enable --now smb.service', self.log.read_text())

    def test_bootstrap_links_restore_guide_without_package_checklists(self):
        script = self.repo / 'bootstrap.sh'
        release = self.root / 'os-release'
        script.write_text((ROOT / 'bootstrap.sh').read_text().replace('/etc/os-release', shlex.quote(str(release))))
        (self.repo / 'bin').mkdir()
        pm = self.repo / 'bin/pm'
        pm.write_text('#!/usr/bin/env bash\nexit 0\n')
        pm.chmod(0o755)
        for distro in ('debian', 'arch', 'omarchy'):
            with self.subTest(distro=distro):
                release.write_text(f'ID={distro}\nVERSION_CODENAME=trixie\n')
                result = self.run_command('bash', str(script))
                if distro == 'omarchy':
                    self.assertNotIn('--bundle omarchy-workstation', result.stdout)
                    preview = subprocess.run(['bash', str(script), '--bundle', 'arch-workstation', '--dry-run'],
                                              env=self.env, text=True, capture_output=True)
                    self.assertEqual(preview.returncode, 0, preview.stderr)
                    self.run_command('bash', str(script), '--bundle', 'arch-workstation', '--bundle', 'imac2011')
                for text in ('setup is not complete', 'packages/restic/README.md'):
                    self.assertIn(text, result.stdout)
                for text in ('Samba', 'smbpasswd', 'restic -r', '~/.ssh', '/etc/ssh'):
                    self.assertNotIn(text, result.stdout)


if __name__ == '__main__':
    unittest.main()
