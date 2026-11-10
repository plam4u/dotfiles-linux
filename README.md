# Linux dotfiles with pm

`pm` installs packages and links configuration files into your home directory.

## Quick start

On Debian 13 or an up-to-date Arch Linux system (x86-64), run these as your
regular user with `sudo` access.

```bash
wget -O- https://github.com/plam4u/dotfiles-debian/raw/main/install.sh | bash
~/dotfiles-debian/bootstrap.sh
```

On Arch, you can use `curl -fsSL` in place of `wget -O-`.

The first command installs Git if needed and clones the public repo to
`~/dotfiles-debian`. The second installs GNU Stow, Bash and Zsh setup, tmux
with xclip, and Vim. GNU Stow links each package's saved config after its
installation. Open a new shell to use `pm` from anywhere. Keep the checkout in
a stable location because the config links point into it.

To preview the basics, run `~/dotfiles-debian/bootstrap.sh --dry-run`.
From the checkout, you can also choose exact packages or combine them with
a bundle:

```bash
./bin/pm install --dry-run vim tmux
./bin/pm install --bundle starter restic
```

Bundles are plain lists in [`bundles/`](bundles/). For the full desktop and
app setup, run `./bootstrap.sh --profile workstation --dry-run` to see the
package plan. Run it without `--dry-run` from a text console after signing
out of XFCE to apply it. The workstation profile chooses the Debian or Arch
bundle and applies the saved desktop and app settings.

## Starter bundle

Bundles run in file order. `starter` installs GNU Stow first, then the shell
package, common tools, tmux and its `xclip` helper, Vim, Telegram, and Docker.
It links the shell, tmux, and Vim configs. A dry run on a system without Stow
shows that linking is planned. Stow can check the individual paths once it is
installed. Both workstation bundles already include the starter packages.

`common-tools` contains utilities such as Git, `curl`, `jq`, `fzf`, and
`ffmpeg`. It has explicit APT and pacman mappings for differences such as
Debian's `bind9-dnsutils` and `bind9-host`, which Arch supplies through `bind`.
Use `./bin/pm install common-tools` to install just those utilities.

Telegram uses system Flathub. Docker uses its vendor APT source on Debian 13
and the native package on Arch. The Debian dry run shows the path to Docker's
install script.

Open a new Bash or Zsh session after installing `shell` to use `pm` from any
directory. The shared PATH snippet finds the checkout through its Stow
symlink. Packages can add shell fragments by putting `.sh` files under
`stow/.bashrc.d/` or `stow/.zshrc.d/`.

The shell package also restores `.profile` for login shells. Both workstation
bundles include the pinned Deno 2.9.8 installer for Linux x86-64. It uses
`~/.deno/bin` and generates missing Bash and Zsh completions.

## Debian workstation packages

The `debian-workstation` bundle targets Debian 13 on amd64. It starts with
the Debian source setup, then installs the recorded desktop, development,
multimedia, networking, and app packages.

The optional `debian-imac12-2-firmware` bundle restores the firmware selection
from this 27-inch iMac (`iMac12,2`), which has Intel integrated graphics and an
AMD Radeon GPU. It installs AMD, Intel, and miscellaneous firmware plus Intel
microcode. Use it when reinstalling this iMac or after checking the hardware
on another machine.

The workstation bootstrap profile applies the package bundle and configuration
follow-ups in order. To run just the package bundle from an existing checkout, use
`./bin/pm install --bundle debian-workstation`.

To preview both bundles together for the iMac:

```bash
./bootstrap.sh --profile imac --dry-run
```

The APT setup adds missing entries for the official Debian mirrors in
`/etc/apt/sources.list.d/pm-debian.sources`. Existing `.list` and `.sources`
entries are used as coverage and left in place. A changed managed file is
backed up. Backports stays available for explicit use. Telegram is installed
via Flatpak. Steam enables the Debian `i386` architecture before installing
the required 32-bit graphics packages.

Brave, ChatGPT, and Docker use their own APT repositories. Obsidian, CLIamp,
and the user copy of yt-dlp use checksummed upstream releases. Neovim uses
the checksummed nightly archive when it matches the recorded build, with a
source build from the recorded commit as a fallback. CLIamp, Neovim, and the
upstream yt-dlp copy install under `~/.local/`. Ensure `~/.local/bin` is on
your `PATH`.

See the [APT inventory](docs/debian-packages.tsv) for the original package
versions, architectures, and restore paths. Debian's installer and APT
dependencies cover the system base. The bundle installs the OpenSSH server.
Restore any existing SSH server configuration and host keys separately when
migrating its identity.

### Back up and restore the iMac system settings

Run these from the checkout as your regular user with your initialized
repository. The workstation bootstrap profile installs Restic. For a manual
setup, run `./bin/pm install restic`.

```bash
./bin/pm-system-settings backup
```

The backup prints each archived file and directory. To see the contents of the
latest system-settings backup, including one you already made, run:

```bash
./bin/pm-system-settings list
```

When prompted for the repository address, enter the full address. Use the
same address for backup and restore.

| Repository location | Example address |
| --- | --- |
| Local folder on a mounted backup drive | `/mnt/backup/restic-debian-imac` |
| Mac over SSH (SFTP) | `sftp:macuser@mac-host.local:restic-debian-imac` |

For the SSH example, replace `macuser` and `mac-host.local` with your Mac
username and hostname. The folder is relative to that user's home directory,
typically `/Users/macuser/restic-debian-imac`.

The backup covers keyd, the Apple keyboard driver override, NetworkManager
profiles, and Samba. Save the repository address and Restic password somewhere
you can access after reinstalling. If the repository is on the Mac, keep a way
to connect from the fresh system, such as an SSH key available independently
of the backup. The user and server SSH backups are separate snapshots.

On fresh Debian, install the workstation bundle and make sure you can access
the backup repository. Then run:

```bash
./bin/pm-system-settings restore
```

The commands ask for the repository address unless `RESTIC_REPOSITORY` or
`RESTIC_REPOSITORY_FILE` is set. Restic asks for the repository password.
Before asking for confirmation, restore lists the files it will install under
`/etc` and any entries it will skip, such as old NetworkManager backup copies
and APT files from earlier snapshots. It backs up changed files and sets
NetworkManager profile permissions. The workstation bundle sets up the APT
sources. To test the backup before reinstalling, run restore now and decline
the confirmation. Reboot after applying the restore on the fresh install.

## Arch workstation packages

On an up-to-date Arch x86-64 install, run from the checkout:

```bash
./bin/pm install --dry-run --bundle arch-workstation
./bin/pm install --bundle arch-workstation
```

`arch-workstation` installs the shared tools, Arch development and desktop
dependencies, XFCE, i3, OpenSSH, and Docker with Compose and Buildx. Arch uses
its repository versions of Obsidian, Neovim, and yt-dlp. CLIamp uses the pinned
upstream binary. Brave and Telegram use Flathub. Start the services you use
after configuration, such as `lightdm.service`, `sshd.service`, or
`docker.service`.

Steam is an optional install on Arch. Enable `multilib` and fully update the
system before running `pm install steam`. The ChatGPT APT package and the
iMac firmware profile target Debian.

## Desktop settings and fonts

The workstation bootstrap profile runs the settings restores in this section. Use the
commands below to apply them individually.

Both workstation bundles link the i3 config, its startup and scratchpad
scripts, and the three saved workspace layout files. On login, i3 launches
Flatpak Telegram and uses the available Brave install. The WhatsApp launcher
runs when its desktop entry has been restored or recreated.

Both bundles install JetBrains Mono Nerd Font 3.5.1 and the saved MesloLGS NF
Regular, Bold, and Italic fonts from pinned, checksum-verified downloads. To
install only the fonts, run `./bin/pm install fonts`. They are installed under
`${XDG_DATA_HOME:-$HOME/.local/share}/fonts`.

The XFCE desktop restore includes both panels and their launchers, keyboard
shortcuts, appearance and window manager settings, and Thunar preferences and
the **Open Terminal Here** action. Launcher buttons use your XFCE preferred
applications. The panel's directory menu opens the restoring user's home.

Preview the restore from the checkout. Apply it from a text console as your
regular user before your first graphical login or after logging out of the
graphical session.

```bash
bash packages/xfce4/post-install.sh --dry-run
bash packages/xfce4/post-install.sh
```

Add `--imac12-2` to include the saved display, pointer, keyboard device, and
power settings for the 27-inch iMac. Changed files get numbered backups next to
the originals. Log in to XFCE after restoring the desktop settings.

After installing `xfce4-terminal`, close XFCE Terminal and run its settings
restore from another terminal in the same desktop session:

```bash
bash packages/xfce4-terminal/post-install.sh
```

The script applies the recorded terminal settings through Xfconf and copies
the shortcut and legacy config files into place, backing up files it changes.
Open XFCE Terminal afterward to load the restored shortcuts.

## Emacs and terminal apps

Both workstation bundles link the saved Emacs init at
`~/.config/emacs/init.el`. Emacs keeps Customize changes in a separate local
`custom.el`. Emacs will use an existing legacy init under `~/.emacs`,
`~/.emacs.el`, or `~/.emacs.d/` ahead of the XDG location.

The btop, htop, and CLIamp snapshots are restored as writable files under
`$XDG_CONFIG_HOME` or `~/.config`. The workstation bootstrap applies them. For a
manual restore, preview from the checkout, close the apps, then rerun the
desired commands without `--dry-run`. Changed files get numbered backups beside
the originals.

```bash
bash packages/common-tools/post-install.sh --dry-run
bash packages/cliamp/post-install.sh --dry-run
```

CLIamp restores shuffle, visualizer, equalizer, and YouTube Music preferences.
Configure account access locally with `cliamp setup`. For native Brave with
GNOME Keyring, the previous setting was `cookies_from = "brave+gnomekeyring"`
under `[ytmusic]` in the local config. Keep credentials, browser cookies,
listening history, and Emacs session files out of Git.

## Existing config files

`pm install` and `pm stow` save conflicting regular files beside the originals
before GNU Stow links the package copies. `pm` prints each backup path. A backup
uses the `.bak` suffix, then `.bak.1`, `.bak.2`, and so on if earlier names are
taken. `pm stow` runs only the config step.

```bash
pm stow --dry-run tmux vim
pm stow tmux vim
```

Review directory conflicts and unrelated symlinks manually. If you linked
`.vimrc` from the old `vim-config` package, unlink that symlink before running
`pm stow vim`. `pm` calls GNU Stow with per-file links and package-local ignore
rules, independently of your personal Stow settings.

## Add a package

`pm add <name>` creates a commented `packages/<name>/install.tsv`. Add
tab-separated `distro`, `installer`, and `target` fields, with one target per
row. Supported installers are `apt`, `pacman`, `flatpak` (Flathub), and `script`
(an `install.sh` in the package directory).

One `pm` package can install multiple system packages. `pm` processes every row
for the detected distro in file order, then links the config. For example, the
`tmux` package installs `tmux` and `xclip` on both Debian and Arch. A comment-only
table with a `stow/` directory is a config-only package. A table with install
rows requires a mapping for the current distro.

Place home files under `stow/` using paths relative to `$HOME`. An optional
`post-install.sh` is listed as a manual follow-up. Bundle files contain one
package name per line, with blank lines and comments allowed.

See the [container test guide](tests/containers/README.md) for Debian and Arch
test environments. Keep SSH keys, browser profiles, and other private app data
in your encrypted backup.
