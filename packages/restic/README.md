# Restore private SSH settings

Install this package with `./bin/pm install restic` from the repository root.
Installation does not restore private settings. To recover SSH settings:

1. Restore user SSH keys and configuration to `~/.ssh`.
2. Restore SSH server configuration and host keys to `/etc/ssh`.

## Connect to the backup repository

Run as your regular user from the repository checkout:

```bash
export RESTIC_REPOSITORY='/mnt/backup/restic-debian-imac'
restic snapshots
```

Use your actual repository address. Examples:

| Repository location | Address |
| --- | --- |
| Mounted backup drive | `/mnt/backup/restic-debian-imac` |
| Mac over SSH | `sftp:macuser@mac-host.local:restic-debian-imac` |

For SFTP, use your Mac username and hostname. The remote folder is relative to
that user's home directory. Keep the repository address, password, and a way
to access it independently of the backup. For example, a fresh machine needs
an SSH key or password to reach an SFTP repository before it can restore keys.

Restic prompts for the repository password. `RESTIC_REPOSITORY_FILE` can replace
`RESTIC_REPOSITORY`. For a read-only backup drive, add `--no-lock` to the Restic
commands you run manually. Select the appropriate repository for each backup;
the user SSH and SSH server backups are separate snapshots.

## User SSH keys and configuration

Find the snapshot containing your old home directory's `.ssh` path:

```bash
restic snapshots
restic ls SNAPSHOT_ID
```

Choose your snapshot ID and old home path. The recorded iMac backup uses snapshot
`fc7d4421` and `/home/plam/.ssh`; replace these values for a different backup:

```bash
user_snapshot=fc7d4421
old_home=/home/plam
umask 077
user_stage=$(mktemp -d)
restic restore "$user_snapshot" --include "$old_home/.ssh" --target "$user_stage" &&
    mkdir -p -m 700 "$HOME/.ssh" &&
    cp -ai -- "$user_stage$old_home/.ssh/." "$HOME/.ssh/"
```

Review overwrite prompts. Run `ssh-add` to load standard key filenames into your
agent, or `ssh-add /path/to/private-key` for a custom filename. Remove the staging
directory once you have checked the restored files.

## SSH server configuration and host keys

Find the `ssh-server` snapshot containing `/etc-ssh.tar`:

```bash
restic snapshots --tag ssh-server
```

The recorded iMac backup uses snapshot `f3b425a8`. Select your snapshot and inspect
the archive before applying it:

```bash
server_snapshot=f3b425a8
umask 077
server_stage=$(mktemp -d)
restic dump "$server_snapshot" /etc-ssh.tar > "$server_stage/etc-ssh.tar" &&
    tar -tf "$server_stage/etc-ssh.tar"
```

The archive contains `etc/ssh/`. Install the OpenSSH server first, then restore
its configuration and keys while preserving a pre-restore copy:

```bash
./bin/pm install openssh-server
sudo tar -xpf "$server_stage/etc-ssh.tar" -C "$server_stage" &&
    sudo cp -a -- /etc/ssh "$server_stage/ssh-before-restore" &&
    sudo cp -a -- "$server_stage/etc/ssh/." /etc/ssh/ &&
    sudo /usr/sbin/sshd -t
```

After validation succeeds, reload SSH using the service for your distribution:

```bash
sudo systemctl reload ssh.service   # Debian
# On Arch, use: sudo systemctl reload sshd.service
```

If restoring over SSH, keep the current session open and test a second
connection after reloading. The pre-restore copy remains at
`"$server_stage/ssh-before-restore"`. Remove the staging directory only after
verifying access.
