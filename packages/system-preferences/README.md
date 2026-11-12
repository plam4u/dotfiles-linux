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
The manifest installs `setxkbmap` on both supported distributions.

`keyboard.sh` installs `defaults/keyd.conf` at `/etc/keyd/default.conf`. It maps
Caps Lock to left Ctrl and Right Command/Meta to a navigation layer, saves
numbered backups of changed configuration, enables and starts keyd, and reloads
its configuration.

On Debian x86-64 `iMac12,2`, the script also installs
`/etc/modprobe.d/imac2011-keyboard.conf`: Fn swaps with left Ctrl, and left Option
swaps with left Command. It rebuilds the initramfs when the options change.
Reboot to load driver changes.

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
user when the corresponding desktop settings tools are installed.

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
