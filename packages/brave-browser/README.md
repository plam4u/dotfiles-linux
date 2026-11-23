# Brave browser

The package installs the native vendor package on Debian and the Brave Flatpak
on Arch. Installation configures `~/downloads` as the default download location
for native and Flatpak profiles, including Default for first launch.

Close Brave before installing or reapplying these preferences:

```bash
bash packages/brave-browser/downloads.sh
```

On Omarchy, `pm` skips the Brave package because the browser is supplied by the
system. Run the script above directly to configure that browser.

The script preserves other preferences and saves numbered backups before changing
existing files. Repeated runs leave matching files unchanged. Download prompting
and other browser settings retain their current values. New additional profiles
use the system XDG download location; the `xdg-user-dirs` package sets that to
`~/downloads`. Download preferences and files remain after uninstall.
