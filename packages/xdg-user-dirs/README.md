# XDG user directories

Run from the repository root:

```bash
./bin/pm install --dry-run xdg-user-dirs
./bin/pm install xdg-user-dirs
```

The package installs `xdg-user-dirs` and links `~/.config/user-dirs.dirs`
and `~/.config/user-dirs.conf` with Stow. Desktop, Downloads, Documents,
and Pictures use `~/desktop`, `~/downloads`, `~/documents`, and `~/pictures`.
Templates, Public, Music, and Videos resolve to the home directory.

`user-dirs.conf` disables automatic updates so `xdg-user-dirs-update` preserves
the symlink and its mappings. Edit `user-dirs.dirs` in this package to change
the mappings, and create any directories you want applications to use.

To apply only the configuration with GNU Stow already installed:

```bash
./bin/pm stow --dry-run xdg-user-dirs
./bin/pm stow xdg-user-dirs
```

Existing folders and their contents are preserved. Applications read the settings
when they next query an XDG directory; reopen applications that cache locations.
Projects is not a standard XDG user directory and is not configured here.
