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

## Omarchy controls

Fcitx5 is an input-method service bundled with Omarchy, rather than a shell/bar
plugin. Omarchy starts it to support input languages and XCompose sequences;
Superwhisper can also use it for direct text insertion.

Open **Omarchy > Setup > Typing > Input Methods** to select input methods, or run
`omarchy setup input`. This controls language selection, not whether the Fcitx
service is running. Fcitx's own settings tool is `fcitx5-configtool`.

To stop Fcitx and block subsequent service activation on Omarchy:

```sh
systemctl --user mask --now omarchy-fcitx5.service
```

Omarchy routes Fcitx's D-Bus activation through this service, so masking also
blocks that activation path. This is a local service preference; Stowing this
package does not enable or disable the service. Disabling Fcitx removes its
input methods and Fcitx-backed Compose sequences and may affect Superwhisper's
direct text insertion.

To restore normal startup and start it immediately:

```sh
systemctl --user unmask omarchy-fcitx5.service
systemctl --user enable --now omarchy-fcitx5.service
```

Check the current state:

```sh
systemctl --user is-enabled omarchy-fcitx5.service
systemctl --user is-active omarchy-fcitx5.service
```

These service commands are Omarchy-specific. Debian and plain Arch use their
desktop's Fcitx startup integration and do not supply this Omarchy unit.

## Services and shell plugins

Omarchy has no single configuration file combining services and shell plugins.

| Component | Control | Configuration |
| --- | --- | --- |
| User services, including Fcitx | `systemctl --user` | `~/.config/systemd/user/` overrides, enablement links and masks |
| System services | `systemctl` | `/etc/systemd/system/` overrides, enablement links and masks |
| Shell/bar plugins | `omarchy plugin list`, `omarchy plugin enable <id>`, `omarchy plugin disable <id>` | `~/.config/omarchy/shell.json`, including `disabledPlugins` |

Use `systemctl --user list-unit-files --type=service` to inspect user-service
enablement, or `systemctl list-unit-files --type=service` for system services.
Fcitx is controlled as a service, so the shell plugin commands do not disable it.
