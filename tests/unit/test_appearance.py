"""Apply desktop appearance against isolated settings tools and temporary homes."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'packages/system-preferences/appearance.sh'


class Appearance(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.release = self.root / 'os-release'
        self.release.write_text('ID=debian\n')
        self.script = self.root / 'appearance.sh'
        self.script.write_text(SCRIPT.read_text().replace('/etc/os-release', str(self.release)))
        self.mock_bin = self.root / 'bin'
        self.mock_bin.mkdir()
        self.config = self.root / 'config'
        self.channels = self.config / 'xfce4/xfconf/xfce-perchannel-xml'
        self.channels.mkdir(parents=True)
        self.log = self.root / 'commands'
        self.env = {**os.environ, 'HOME': str(self.root),
                    'XDG_CONFIG_HOME': str(self.config),
                    'PATH': str(self.mock_bin) + ':' + os.environ['PATH'],
                    'APPEARANCE_LOG': str(self.log)}
        self.env.pop('DBUS_SESSION_BUS_ADDRESS', None)
        self.mock('dbus-run-session', '''
import os
import sys
os.environ['DBUS_SESSION_BUS_ADDRESS'] = 'mock-session'
os.execvp(sys.argv[2], sys.argv[2:])
''')
        self.mock('gsettings', '''
import os
import sys
from pathlib import Path
if sys.argv[1] == 'list-schemas':
    if not os.environ.get('NO_INTERFACE_SCHEMA'):
        print('org.gnome.desktop.interface')
else:
    with Path(os.environ['APPEARANCE_LOG']).open('a') as log:
        log.write('gsettings ' + ' '.join(sys.argv[1:]) + '\\n')
''')
        self.mock('xfconf-query', '''
import os
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
args = sys.argv[1:]
channel = args[args.index('--channel') + 1]
parts = args[args.index('--property') + 1].strip('/').split('/')
path = Path(os.environ['XDG_CONFIG_HOME']) / 'xfce4/xfconf/xfce-perchannel-xml' / (channel + '.xml')
root = ET.parse(path).getroot() if path.exists() else ET.Element('channel', name=channel, version='1.0')
node = root
for index, part in enumerate(parts):
    child = node.find(f"property[@name='{part}']")
    if child is None:
        if '--set' not in args:
            sys.exit(1)
        child = ET.SubElement(node, 'property', name=part, type='empty')
    node = child
if '--set' not in args:
    print(node.get('value', ''))
else:
    node.set('type', args[args.index('--type') + 1])
    node.set('value', args[args.index('--set') + 1])
    # Deliberately write through symlinks: the caller must detach them first.
    ET.ElementTree(root).write(path)
    with Path(os.environ['APPEARANCE_LOG']).open('a') as log:
        log.write('xfconf ' + ' '.join(args) + '\\n')
''')
        source = ROOT / 'packages/xfce4/stow/.config/xfce4/xfconf/xfce-perchannel-xml'
        self.templates = self.root / 'templates'
        self.templates.mkdir()
        for channel in ('xsettings', 'xfwm4'):
            template = self.templates / (channel + '.xml')
            shutil.copyfile(source / template.name, template)
            (self.channels / template.name).symlink_to(template)
        self.originals = {path: path.read_bytes() for path in self.templates.iterdir()}

    def mock(self, name, code):
        path = self.mock_bin / name
        path.write_text('#!' + sys.executable + '\n' + code)
        path.chmod(0o755)

    def run_script(self, *args):
        result = subprocess.run(['bash', str(self.script), *args], env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_omarchy_preserves_its_active_theme(self):
        self.release.write_text('ID=omarchy\n')
        result = self.run_script()
        self.assertIn('Keeping the active Omarchy theme', result.stdout)
        self.assertFalse(self.log.exists())

    def test_apply_preserves_templates_other_settings_and_repeat(self):
        self.run_script()
        for path, original in self.originals.items():
            self.assertEqual(path.read_bytes(), original)
            destination = self.channels / path.name
            self.assertFalse(destination.is_symlink())
            self.assertTrue((self.channels / (path.name + '.~1~')).is_symlink())
        xsettings = ET.parse(self.channels / 'xsettings.xml').getroot()
        self.assertEqual(xsettings.find("./property[@name='Net']/property[@name='ThemeName']").get('value'), 'Adwaita-dark')
        self.assertEqual(xsettings.find("./property[@name='Gtk']/property[@name='CanChangeAccels']").get('value'), 'true')
        xfwm = ET.parse(self.channels / 'xfwm4.xml').getroot()
        self.assertEqual(xfwm.find("./property[@name='general']/property[@name='workspace_count']").get('value'), '5')
        self.assertIn('color-scheme prefer-dark', self.log.read_text())
        writes = self.log.read_text().count('xfconf ')
        self.run_script()
        self.assertEqual(self.log.read_text().count('xfconf '), writes)
        self.assertFalse(list(self.channels.glob('*.~2~')))

    def test_dry_run_preserves_files_and_never_sets_preferences(self):
        result = self.run_script('--dry-run')
        self.assertIn('color-scheme prefer-dark', result.stdout)
        self.assertIn('/Net/ThemeName', result.stdout)
        self.assertFalse(self.log.exists())
        for path, original in self.originals.items():
            self.assertEqual(path.read_bytes(), original)
            self.assertTrue((self.channels / path.name).is_symlink())
        self.assertFalse(list(self.channels.glob('*.~*~')))

    def test_missing_gnome_schema_still_applies_xfce(self):
        self.env['NO_INTERFACE_SCHEMA'] = '1'
        self.run_script()
        self.assertNotIn('gsettings ', self.log.read_text())
        self.assertIn('xfconf ', self.log.read_text())


if __name__ == '__main__':
    unittest.main()
