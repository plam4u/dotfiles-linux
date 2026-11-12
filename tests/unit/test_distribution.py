"""Check installer distribution selection without changing the host."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


@unittest.skipIf(os.geteuid() == 0, 'installer requires a regular user')
class Distribution(unittest.TestCase):
    def test_checkout_installer_accepts_arch_and_omarchy(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            home = root / 'home'
            checkout = home / 'dotfiles-linux'
            (checkout / '.git').mkdir(parents=True)
            (checkout / 'bootstrap.sh').touch()
            mock_bin = root / 'bin'
            mock_bin.mkdir()
            git = mock_bin / 'git'
            git.write_text('#!/usr/bin/env bash\nprintf "%s\\n" https://github.com/plam4u/dotfiles-linux.git\n')
            git.chmod(0o755)
            release = root / 'os-release'
            installer = root / 'install.sh'
            installer.write_text((ROOT / 'install.sh').read_text().replace('/etc/os-release', str(release)))
            env = {**os.environ, 'HOME': str(home), 'PATH': str(mock_bin) + ':' + os.environ['PATH']}
            for distro in ('arch', 'omarchy', 'debian', 'unsupported'):
                with self.subTest(distro=distro):
                    release.write_text(f'ID={distro}\nVERSION_CODENAME=trixie\n')
                    result = subprocess.run(['bash', str(installer)], env=env, text=True, capture_output=True)
                    if distro == 'unsupported':
                        self.assertNotEqual(result.returncode, 0)
                    else:
                        self.assertEqual(result.returncode, 0, result.stderr)
                        self.assertIn('Dotfiles are ready', result.stdout)

    def test_combined_bundles_select_the_omarchy_desktop(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            repo = root / 'repo'
            for directory in ('bin', 'bundles', 'packages'):
                shutil.copytree(ROOT / directory, repo / directory)
            home = root / 'home'
            home.mkdir()
            release = root / 'os-release'
            release.write_text('ID=omarchy\nID_LIKE=arch\n')
            model = root / 'model'
            model.write_text('iMac12,2\n')
            pm = repo / 'bin/pm'
            pm.write_text(pm.read_text().replace('/etc/os-release', str(release)).replace(
                '/sys/devices/virtual/dmi/id/product_name', str(model)))
            bootstrap = repo / 'bootstrap.sh'
            bootstrap.write_text((ROOT / 'bootstrap.sh').read_text().replace('/etc/os-release', str(release)))
            args = ['--bundle', 'arch-workstation', '--bundle', 'imac2011',
                    '--bundle', 'basics', '--bundle', 'starter', '--dry-run']
            env = {**os.environ, 'HOME': str(home)}
            for command in (['bash', str(pm), 'install'], ['bash', str(bootstrap)]):
                result = subprocess.run([*command, *args], env=env, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn('Using omarchy-workstation', result.stdout)
                for expected in ('wl-clipboard', '/mbpfan/arch.sh', 'intel-ucode',
                                 '/system-preferences/hyprland.sh', 'linux-firmware-radeon'):
                    self.assertIn(expected, result.stdout)
                for excluded in ('lightdm', 'xfce4', 'i3-wm', 'post-install.sh'):
                    self.assertNotIn(excluded, result.stdout)
                self.assertEqual(result.stdout.splitlines().count('tmux'), 1)
            release.write_text('ID=arch\n')
            result = subprocess.run(['bash', str(pm), 'install', *args], env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('lightdm', result.stdout)
            self.assertIn('i3-wm', result.stdout)
            self.assertNotIn('Using omarchy-workstation', result.stdout)
