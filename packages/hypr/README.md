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
`monitors.lua`, `looknfeel.lua`, `qconsole.lua` and `autostart.lua`. Edit them here or through the
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

## Login applications

Workspace 1 opens Foot attached to tmux session `main`. A new session contains
`code` and `shell` windows in your home directory and a `dotfiles` window in this
checkout, with `code` selected. An existing `main` session is reused unchanged.
Window names stay fixed. Run `~/.local/bin/hypr-main-terminal` to open it manually.

Workspace 2 opens the default browser through Omarchy's browser launcher.
The package installs Brave and routes Brave/Chromium windows to workspace 2.
Workspace 3 opens Telegram (Flatpak) and WhatsApp Web through Omarchy's web-app
launcher. WhatsApp requires a supported Chromium-based default browser and may
require login. Rules use silent placement to avoid startup focus changes.
These applications start on the next desktop login, not on config reload.

## Window navigation

Super+H/J/K/L focuses left/down/up/right. Adding Shift swaps the focused window
in that direction, matching the existing arrow-key bindings. Displaced actions:

- Super+semicolon: toggle split (previously Super+J).
- Super+F1: keybinding help (previously Super+K).
- Super+E / Super+Alt+E: cycle workspace layout forward/backward (previously
  Super+L / Super+Alt+L).

## Drop-down console

`~/.config/hypr/qconsole.lua` replaces Omarchy's packaged console module.
`local share = 0.7` sets its height to 70% of the usable screen.
`width_share = 0.5` and `box = 2` preserve the original single-window width;
multiple windows still use the full width.
