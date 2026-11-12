# Samba

Run commands from the repository root:

```bash
./bin/pm install --dry-run samba
./bin/pm install samba
sudo smbpasswd -a "$(id -un)"
```

Installation validates the saved configuration with `testparm`, substitutes your
home and username, creates `~/Public`, and installs `/etc/samba/smb.conf` with
numbered backups. It reloads Samba if it is already running.

The `Public` share allows authenticated access to `~/Public`. Set your Samba
password with the command above. Start `smbd.service` on Debian or `smb.service`
on Arch when you want to serve shares:

```bash
sudo systemctl enable --now smbd.service   # Debian
# On Arch: sudo systemctl enable --now smb.service
```

Uninstall keeps configuration, accounts and shared files.
