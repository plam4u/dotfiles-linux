# XFCE desktop

Run from the repository root:

```bash
./bin/pm install xfce4
bash packages/xfce4/post-install.sh --dry-run
bash packages/xfce4/post-install.sh
```

Installation enables LightDM and graphical login for the next boot, allowing
the offline restore to finish before first sign-in. Reboot afterward to enter
the configured desktop.

Apply the restore from a text console before graphical login or after signing
out of XFCE. The script refuses to apply while XFCE or Xfconf is running.
`XDG_CONFIG_HOME` must be unset or equal to `~/.config`.

The restore includes panels and launchers, keyboard shortcuts, window manager
behavior, Thunar settings and the **Open Terminal Here** action. Launchers use
your XFCE preferred applications. Stow links the saved files; the restore script
generates panel XML with your home directory and backs up changed panel files.

The script reapplies [shared desktop appearance](../system-preferences/README.md)
after linking XFCE settings. This ordering keeps the desktop restore from
replacing appearance preferences. Log in again afterward.

Add `--imac2011` to include the saved display, pointer, keyboard-repeat and
power settings for `iMac12,2`. Workstation bootstrap runs the appropriate
desktop restore automatically.
