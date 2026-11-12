# Foot

Install from the repository root in a Wayland desktop session:

```bash
./bin/pm install --dry-run foot
./bin/pm install foot
```

The package installs Foot and runs the shared fonts installer to provide
JetBrainsMono Nerd Font and MesloLGS NF. Stow links
`stow/.config/foot/foot.ini` to `~/.config/foot/foot.ini`, preserving existing
configuration with numbered backups. To link configuration only:

```bash
./bin/pm stow --dry-run foot
./bin/pm stow foot
```

Customize `stow/.config/foot/foot.ini` here, or edit the linked file in your home.
Change `font` under `[main]` for the family and size, `pad` for padding,
`[scrollback]` for history, and `[key-bindings]` for shortcuts. The configuration
uses Foot's default colors and has no dependency on Omarchy themes.
Open a new Foot window after editing. See `man foot.ini` for all options.

Foot has no built-in tabs or split panes; use a multiplexer such as tmux for
those features.
