# Fcitx5

Install on Debian 13 or Arch/Omarchy with `./bin/pm install fcitx5`.
Use `./bin/pm stow fcitx5` to link configuration only.

Includes Fcitx5, its settings tool, GTK/Qt application integration, and Chinese
input methods. Startup uses the distribution's XDG autostart and D-Bus activation;
no additional service is installed. On a new installation, log out and back in
so the desktop can load its input-method integration. KDE Wayland users must
select Fcitx 5 under System Settings > Keyboard > Virtual Keyboard.

The captured configuration uses the US keyboard. Pinyin cloud prediction is off.
Ctrl+Alt+J enables completion temporarily; Ctrl+Alt+H toggles completion.
Completion is off by default. Ctrl+Space is left available for terminal use;
input-method switching uses the configured Japanese/Korean keys or left Shift.
Omarchy also supplies its own Super+I desktop binding.

The Omarchy candidate-window theme is included, with icons copied from Fcitx5's
packaged default theme. Runtime caches, notification-dismissal state and backups
are excluded. On an existing session, reload the linked keyboard addon through
Fcitx's configuration API or log out and back in.
