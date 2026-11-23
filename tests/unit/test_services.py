"""Check fresh installs activate required services without touching the host."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


@unittest.skipIf(os.geteuid() == 0, 'pm requires a regular user')
class Services(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='pm-services-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.repo = self.root / 'repo'
        self.home = self.root / 'home'
        self.mock_bin = self.root / 'mock-bin'
        for path in (self.repo / 'bin', self.repo / 'packages', self.home, self.mock_bin):
            path.mkdir(parents=True)
        self.release = self.root / 'os-release'
        self.log = self.root / 'commands'
        self.env = {**os.environ, 'HOME': str(self.home),
                    'PATH': str(self.mock_bin) + ':' + os.environ['PATH'],
                    'SERVICE_TEST_LOG': str(self.log)}
        (self.repo / 'bin/pm').write_text((ROOT / 'bin/pm').read_text().replace('/etc/os-release', str(self.release)))
        self.native = ('bluez', 'blueman', 'bluez-utils', 'cron', 'keyd', 'logrotate',
                       'network-manager-gnome', 'openssh-server')
        for package in (*self.native, 'docker', 'xfce4'):
            directory = self.repo / 'packages' / package
            shutil.copytree(ROOT / 'packages' / package, directory)
            for script in directory.glob('*.sh'):
                script.write_text(script.read_text().replace('/etc/os-release', str(self.release)))
        self.mock('dpkg', "print('amd64')")
        self.mock('sudo', '''
import os
import sys
os.execvp(sys.argv[1], sys.argv[1:])
''')
        self.mock('systemctl', '''
import os
from pathlib import Path
import sys
args = sys.argv[1:]
if args[0] == 'cat':
    sys.exit(1 if os.environ.get('SERVICE_TEST_MISSING') else 0)
with Path(os.environ['SERVICE_TEST_LOG']).open('a') as log:
    log.write('systemctl ' + ' '.join(args) + '\\n')
if args[0] == 'enable' and args[-1] == os.environ.get('SERVICE_TEST_FAIL'):
    sys.exit(1)
''')
        manager = '''
import os
from pathlib import Path
import sys
program = Path(sys.argv[0]).name
args = sys.argv[1:]
if program == 'dpkg-query' or (program == 'pacman' and args[0] in ('-Q', '-Qg')):
    if not os.environ.get('SERVICE_TEST_INSTALLED'):
        sys.exit(1)
    print('installed')
    sys.exit(0)
with Path(os.environ['SERVICE_TEST_LOG']).open('a') as log:
    log.write(program + ' ' + ' '.join(args) + '\\n')
'''
        for name in ('apt-get', 'pacman', 'dpkg-query'):
            self.mock(name, manager)

    def mock(self, name, code):
        path = self.mock_bin / name
        path.write_text('#!' + sys.executable + '\n' + code)
        path.chmod(0o755)

    def run_pm(self, *args, succeeds=True):
        result = subprocess.run(['bash', str(self.repo / 'bin/pm'), *args], env=self.env,
                                text=True, capture_output=True)
        if succeeds:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def commands(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_services_start_after_dependencies_and_stop_before_removal(self):
        for distro in ('debian', 'arch', 'omarchy'):
            with self.subTest(distro=distro):
                self.release.write_text(f'ID={distro}\nVERSION_CODENAME=trixie\n')
                self.log.unlink(missing_ok=True)
                self.env.pop('SERVICE_TEST_INSTALLED', None)
                self.env.pop('SERVICE_TEST_MISSING', None)
                self.run_pm('install', '--dry-run', *self.native)
                self.assertEqual(self.commands(), [])
                self.run_pm('install', *self.native)
                commands = self.commands()
                for package, dependency, unit in (
                    ('keyd', 'keyd', 'keyd.service'),
                    ('cron', 'cron' if distro == 'debian' else 'cronie', 'cron.service' if distro == 'debian' else 'cronie.service'),
                    ('openssh-server', 'task-ssh-server' if distro == 'debian' else 'openssh', 'ssh.service' if distro == 'debian' else 'sshd.service'),
                    ('network-manager-gnome', 'network-manager' if distro == 'debian' else 'networkmanager', 'NetworkManager.service'),
                    ('logrotate', 'logrotate', 'logrotate.timer'),
                    ('blueman', 'bluez', 'bluetooth.service'),
                ):
                    native = ('apt-get install -y -- ' if distro == 'debian' else 'pacman -S --needed --noconfirm -- ') + dependency
                    self.assertLess(commands.index(native), commands.index('systemctl enable --now ' + unit), package)
                self.env['SERVICE_TEST_INSTALLED'] = '1'
                self.run_pm('uninstall', *self.native)
                commands = self.commands()
                remove = ('apt-get remove -y -- ' if distro == 'debian' else 'pacman -R --noconfirm -- ') + 'keyd'
                self.assertLess(commands.index('systemctl disable --now keyd.service'), commands.index(remove))
                self.env.pop('SERVICE_TEST_INSTALLED')
                self.env['SERVICE_TEST_MISSING'] = '1'
                self.run_pm('uninstall', *self.native)

    def test_activation_failure_is_reported(self):
        self.release.write_text('ID=arch\n')
        self.env['SERVICE_TEST_FAIL'] = 'keyd.service'
        self.run_pm('install', 'keyd', succeeds=False)
        self.assertIn('systemctl enable --now keyd.service', self.commands())

    def test_docker_activation_is_shared_and_follows_native_install(self):
        self.release.write_text('ID=debian\nVERSION_CODENAME=trixie\n')
        preview = self.run_pm('install', '--dry-run', 'docker').stdout
        self.assertLess(preview.index('/docker/debian.sh'), preview.index('/docker/install.sh'))
        self.assertEqual(self.commands(), [])
        self.release.write_text('ID=arch\n')
        self.run_pm('install', 'docker')
        commands = self.commands()
        self.assertLess(commands.index('pacman -S --needed --noconfirm -- docker-compose'),
                        commands.index('systemctl enable --now docker.service'))
        self.env['SERVICE_TEST_INSTALLED'] = '1'
        self.run_pm('uninstall', 'docker')
        commands = self.commands()
        self.assertLess(commands.index('systemctl disable --now docker.service'),
                        commands.index('pacman -R --noconfirm -- docker'))
        self.assertIn('systemctl disable --now docker.socket', commands)

    def test_graphical_login_waits_for_offline_desktop_setup(self):
        self.release.write_text('ID=arch\n')
        result = subprocess.run(['bash', str(self.repo / 'packages/xfce4/install.sh')],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands(), ['systemctl enable lightdm.service',
                                          'systemctl set-default graphical.target'])
        self.assertIn('next boot', result.stdout)


if __name__ == '__main__':
    unittest.main()
