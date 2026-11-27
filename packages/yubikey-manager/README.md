# YubiKey Manager

From the repository root, run `./bin/pm install yubikey-manager` on Debian 13
or Arch. The installer enables `pcscd.socket` for smart-card access on demand.

Plug in your YubiKey and run `ykman list` to find it or `ykman info` to see its
firmware and enabled interfaces. If the key was already plugged in during
installation, reconnect it to apply the udev rules.
