# XFCE Terminal

Run from the repository root:

```bash
./bin/pm install xfce4-terminal
bash packages/xfce4-terminal/post-install.sh
```

Close XFCE Terminal first and run the restore from another terminal in the same
user D-Bus session. `XDG_CONFIG_HOME` must be unset or equal to `~/.config`.

Stow links shortcuts and terminal configuration files. The restore applies the
recorded palette, font, scrollbar, menu, copy-selection and paste preferences
through Xfconf, preserving numbered backups of changed channel files. Open XFCE
Terminal afterward to load restored shortcuts.

Workstation bootstrap runs this follow-up automatically.
