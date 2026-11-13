# Hyprland personal configuration

This package targets Omarchy's Lua-based Hyprland setup. It declares Omarchy as
its dependency and is included in the Omarchy workstation bundle. It is not a
standalone Debian/i3 desktop configuration.

```bash
./bin/pm stow --dry-run hypr
./bin/pm stow hypr
hyprctl reload
hyprctl configerrors
```

Stow tracks the main `hyprland.lua` entry point and personal `bindings.lua`,
`monitors.lua`, `looknfeel.lua` and `autostart.lua`. Edit them here or through the
links in `~/.config/hypr/`. Existing files are backed up by the package manager.
The entry point continues loading Omarchy's packaged defaults.

`input.lua` belongs to the system-preferences package's keyboard setup and stays
outside this package. Night-light and portal configuration belong to their
respective services; generated files and backups are not tracked here.

Screenshot shortcuts copy directly to the clipboard:

- Super+Shift+S: select a region (replaces Omarchy's Google Maps shortcut).
- F12: capture the full screen.
- Super+F12: choose a window to capture.

The original Print Screen shortcuts remain available. Hyprland reloads Lua
changes automatically; use the commands above to explicitly validate edits.
