#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
import os
from pathlib import Path
import shutil
import tempfile

# Chromium rewrites Preferences on exit, so only edit closed browser profiles.
for process in Path('/proc').glob('[0-9]*/cmdline'):
    try:
        executable = process.read_bytes().split(b'\0', 1)[0].decode()
    except (OSError, UnicodeError):
        continue
    if Path(executable).name in ('brave', 'brave-browser', 'brave-browser-stable'):
        raise SystemExit('Close Brave before applying its download preferences, then rerun this script.')

home = Path.home()
downloads = home / 'downloads'
downloads.mkdir(exist_ok=True)
roots = (
    Path(os.environ.get('XDG_CONFIG_HOME', home / '.config')) / 'BraveSoftware/Brave-Browser',
    home / '.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser',
)
for root in roots:
    # Seed Default for first launch and update all existing Chromium profiles.
    profiles = {root / 'Default'}
    profiles.update(root.glob('Profile *'))
    for profile in sorted(profiles):
        path = profile / 'Preferences'
        preferences = json.loads(path.read_text()) if path.exists() else {}
        download = preferences.setdefault('download', {})
        if download.get('default_directory') == str(downloads):
            continue
        download['default_directory'] = str(downloads)
        profile.mkdir(parents=True, exist_ok=True)
        if path.exists():
            index = 1
            backup = path.with_name(f'Preferences.bak.{index}')
            while backup.exists():
                index += 1
                backup = path.with_name(f'Preferences.bak.{index}')
            shutil.copy2(path, backup)
        with tempfile.NamedTemporaryFile(mode='w', dir=profile, delete=False) as output:
            temporary = Path(output.name)
            json.dump(preferences, output, separators=(',', ':'))
            output.write('\n')
        temporary.replace(path)
        print(f'Configured Brave downloads: {path} -> {downloads}')
PY
