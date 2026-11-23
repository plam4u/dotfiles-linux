"""Exercise keyboard setup without changing host configuration or services."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class Keyboard(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.package = self.root / 'packages/system-preferences'
        shutil.copytree(ROOT / 'packages/system-preferences', self.package)
        shutil.copytree(ROOT / 'share', self.root / 'share')
        self.release = self.root / 'os-release'
        self.release.write_text('ID=debian\n')
        self.model = self.root / 'model'
        self.model.write_text('iMac12,2\n')
        self.config = self.root / 'etc'
        self.mock_bin = self.root / 'bin'
        self.mock_bin.mkdir()
        self.log = self.root / 'commands'
        self.env = {**os.environ, 'PATH': str(self.mock_bin) + ':' + os.environ['PATH'],
                    'KEYBOARD_LOG': str(self.log), 'KEYBOARD_ARCH': 'x86_64'}
        # Redirect system paths only in the isolated copy of the scripts.
        for path in self.package.rglob('*.sh'):
            text = path.read_text().replace('/etc/keyd/', str(self.config / 'keyd') + '/')
            text = text.replace('/etc/modprobe.d/', str(self.config / 'modprobe.d') + '/')
            text = text.replace('/etc/os-release', str(self.release))
            text = text.replace('/sys/devices/virtual/dmi/id/product_name', str(self.model))
            path.write_text(text)
        self.mock('uname', "import os\nprint(os.environ['KEYBOARD_ARCH'])\n")
        self.mock('keyd.rvaiya', '')
        self.mock('mkinitcpio', '')
        self.mock('limine-mkinitcpio', '')
        self.mock('systemctl', '''
import os
from pathlib import Path
import sys
if sys.argv[1] != 'cat':
    with Path(os.environ['KEYBOARD_LOG']).open('a') as log:
        log.write('systemctl ' + ' '.join(sys.argv[1:]) + '\\n')
''')
        self.mock('sudo', '''
import os
from pathlib import Path
import subprocess
import sys
args = sys.argv[1:]
if args[0] == 'install':
    # Run real GNU install and its backup handling as the test user.
    for option in ('-o', '-g'):
        index = args.index(option)
        del args[index:index + 2]
elif Path(args[0]).name in ('keyd', 'keyd.rvaiya', 'update-initramfs', 'mkinitcpio', 'limine-mkinitcpio'):
    with Path(os.environ['KEYBOARD_LOG']).open('a') as log:
        log.write(' '.join([Path(args[0]).name, *args[1:]]) + '\\n')
    sys.exit(0)
sys.exit(subprocess.run(args).returncode)
''')
        self.keyd = self.config / 'keyd/default.conf'
        self.apple = self.config / 'modprobe.d/imac2011-keyboard.conf'

    def mock(self, name, code):
        path = self.mock_bin / name
        path.write_text('#!' + sys.executable + '\n' + code)
        path.chmod(0o755)

    def run_script(self, name, succeeds=True):
        result = subprocess.run(['bash', str(self.package / name)], env=self.env,
                                text=True, capture_output=True)
        if succeeds:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def commands(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_install_backups_repeat_and_matching_uninstall(self):
        self.keyd.parent.mkdir(parents=True)
        self.keyd.write_text('previous keyboard configuration')
        self.run_script('keyboard.sh')
        self.assertEqual(self.keyd.read_bytes(), (self.package / 'defaults/keyd.conf').read_bytes())
        self.assertEqual(self.keyd.with_name('default.conf.~1~').read_text(), 'previous keyboard configuration')
        self.assertEqual(self.apple.read_bytes(), (self.package / 'defaults/imac2011-keyboard.conf').read_bytes())
        self.run_script('keyboard.sh')
        self.assertFalse(self.keyd.with_name('default.conf.~2~').exists())
        self.assertEqual(self.commands().count('update-initramfs -u'), 1)
        self.assertEqual(self.commands().count('keyd.rvaiya reload'), 2)
        self.run_script('uninstall.sh')
        self.assertFalse(self.keyd.exists())
        self.assertFalse(self.apple.exists())
        self.assertEqual(self.commands().count('update-initramfs -u'), 2)
        self.run_script('uninstall.sh')
        self.assertEqual(self.commands().count('update-initramfs -u'), 2)

    def test_apple_settings_require_x86_imac(self):
        for distro, architecture, model in (('debian', 'x86_64', 'other'),
                                            ('debian', 'aarch64', 'iMac12,2')):
            with self.subTest(distro=distro, architecture=architecture, model=model):
                self.release.write_text('ID=' + distro + '\n')
                self.env['KEYBOARD_ARCH'] = architecture
                self.model.write_text(model + '\n')
                self.run_script('keyboard.sh')
                self.assertTrue(self.keyd.exists())
                self.assertFalse(self.apple.exists())
        self.assertNotIn('update-initramfs -u', self.commands())

    def test_apple_settings_rebuild_arch_and_omarchy_boot_images(self):
        for distro, command in (('arch', 'mkinitcpio -P'), ('omarchy', 'limine-mkinitcpio')):
            with self.subTest(distro=distro):
                self.release.write_text('ID=' + distro + '\n')
                self.run_script('keyboard.sh')
                self.assertTrue(self.apple.exists())
                self.assertIn(command, self.commands())
                self.run_script('uninstall.sh')
                self.assertFalse(self.apple.exists())
                self.assertEqual(self.commands().count(command), 2)

    def test_uninstall_preserves_edits_and_symlinks(self):
        self.run_script('keyboard.sh')
        self.keyd.write_text('edited config')
        self.apple.write_text('edited driver options')
        before = self.commands()
        self.run_script('uninstall.sh')
        self.assertEqual(self.keyd.read_text(), 'edited config')
        self.assertEqual(self.apple.read_text(), 'edited driver options')
        self.assertEqual(self.commands(), before + ['systemctl disable --now keyd.service'])
        for destination, name in ((self.keyd, 'keyd.conf'), (self.apple, 'imac2011-keyboard.conf')):
            destination.unlink()
            destination.symlink_to(self.package / 'defaults' / name)
        self.run_script('uninstall.sh')
        self.assertTrue(self.keyd.is_symlink())
        self.assertTrue(self.apple.is_symlink())
        self.assertEqual(self.commands(), before + ['systemctl disable --now keyd.service'] * 2)

    def test_install_refuses_symlink_and_activates_keyd(self):
        self.keyd.parent.mkdir(parents=True)
        target = self.root / 'private-config'
        target.write_text('private')
        self.keyd.symlink_to(target)
        self.run_script('keyboard.sh', succeeds=False)
        self.assertEqual(target.read_text(), 'private')
        self.keyd.unlink()
        self.run_script('keyboard.sh')
        self.assertLess(self.commands().index('systemctl enable --now keyd.service'),
                        self.commands().index('keyd.rvaiya reload'))


if __name__ == '__main__':
    unittest.main()
