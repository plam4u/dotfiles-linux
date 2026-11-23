# NordVPN

Run these commands from the repository root:

```sh
./bin/pm install --dry-run nordvpn
./bin/pm install nordvpn
```

On Debian, the package uses [NordVPN's official APT repository](https://support.nordvpn.com/hc/en-us/articles/38295918469393-I-can-t-install-or-update-the-NordVPN-app-on-Linux).
APT may also install the recommended NordVPN GUI. On Arch x86-64, the package
uses a local PKGBUILD to repackage the checksum-pinned vendor CLI.

If the installer reports a group membership change, log out and back in.
Run `nordvpn login` to authenticate, then `nordvpn connect` to connect.

To remove the package, preview with `./bin/pm uninstall --dry-run nordvpn`,
then run `./bin/pm uninstall nordvpn`.
