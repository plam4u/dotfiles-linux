# System preferences

Run from the repository root:

```bash
./bin/pm install --dry-run system-preferences
./bin/pm install system-preferences
```

The manifest installs keyd before applying keyboard configuration. It also runs
the timezone and appearance scripts in manifest order.

## Keyboard

Stow links `~/.local/bin/keyboard-layout.sh`, which runs:

```sh
setxkbmap -layout us -variant altgr-intl
```

An XDG autostart entry runs it at graphical login in XFCE and in the repository's
i3 setup (through dex). To apply it immediately, run `~/.local/bin/keyboard-layout.sh`.
The manifest installs `setxkbmap` on Debian and Arch. The autostart helper
exits without changing anything in a Wayland session.

On Omarchy, `hyprland.sh` appends a US `altgr-intl` layout override to the user's
`~/.config/hypr/input.lua`, preserving other input settings and saving a numbered
backup. Repeated installation does not append duplicate overrides. It reloads
and checks the running Hyprland configuration, or reports that it will apply at
next login when run outside the graphical session. The installed layout remains
on uninstall, like the timezone and appearance preferences.

`keyboard.sh` installs `defaults/keyd.conf` at `/etc/keyd/default.conf`. It maps
Caps Lock to left Ctrl and Right Command/Meta to a navigation layer, saves
numbered backups of changed configuration, enables and starts keyd, and reloads
its configuration.

On x86-64 `iMac12,2`, the script also installs
`/etc/modprobe.d/imac2011-keyboard.conf`: Fn swaps with left Ctrl, and left Option
swaps with left Command. It rebuilds the initramfs when the options change.
Debian uses `update-initramfs`, Arch uses `mkinitcpio`, and Omarchy uses
`limine-mkinitcpio` to rebuild the boot images. Reboot to load driver changes.

After installing the package, reapply just keyboard preferences with:

```bash
bash packages/system-preferences/keyboard.sh
```

## Timezone

`timezone.sh` sets the system timezone to `Europe/Madrid` using `timedatectl`.

## Appearance

`appearance.sh` sets the GNOME dark color scheme, Adwaita-dark GTK theme and
shared XFCE appearance: cursor theme, font rendering, scaling, window
decorations, opacity, shadows and compositing. Settings apply to the current
user when the corresponding desktop settings tools are installed. On Omarchy,
the script preserves the active Omarchy theme instead of applying these changes.

```bash
bash packages/system-preferences/appearance.sh --dry-run
bash packages/system-preferences/appearance.sh
```

Appearance updates preserve other Xfconf properties and save numbered backups of
changed channel files. Stow links become regular files before writing, keeping
the checkout unchanged. The [XFCE restore](../xfce4/README.md) reapplies these
settings after linking its configuration. Application-specific appearance stays
with its owning package.

## Uninstall

Uninstall stops and disables keyd. It removes keyboard configuration only when
it still matches the saved defaults and rebuilds the initramfs if the Apple
driver file was removed. Edited
files and backups remain. Timezone and appearance settings remain in effect.
The manifest's keyd dependency is also removed.
