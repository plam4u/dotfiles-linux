# XDG user directories

Run from the repository root:

```bash
./bin/pm install --dry-run xdg-user-dirs
./bin/pm install xdg-user-dirs
```

The package installs `xdg-user-dirs` and Stow links
`~/.config/user-dirs.dirs`. Downloads, Documents, and Pictures use their own
folders. Desktop, Templates, Public, Music, and Videos resolve to the home
directory, disabling dedicated folders for those locations.

To apply only the configuration with GNU Stow already installed:

```bash
./bin/pm stow --dry-run xdg-user-dirs
./bin/pm stow xdg-user-dirs
```

Existing folders and their contents are preserved. Applications read the settings
when they next query an XDG directory; reopen applications that cache locations.
Projects is not a standard XDG user directory and is not configured here.
