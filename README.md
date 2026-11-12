# Linux dotfiles with pm

`pm` installs packages and links configuration files into your home directory.

## Quick start

On Debian 13 (amd64 or arm64) or an up-to-date Arch Linux system (x86-64),
run these as your regular user with `sudo` access.

```bash
wget -O- https://github.com/plam4u/dotfiles-linux/raw/main/install.sh | bash
~/dotfiles-linux/bootstrap.sh
```

On Arch, you can use `curl -fsSL` in place of `wget -O-`.

The first command installs Git if needed and clones the public repo to
`~/dotfiles-linux`. The second installs the [basics bundle](bundles/basics).
It includes GNU Stow, Bash and Zsh, tmux with xclip, Vim, packaged Neovim,
Emacs, GCC, Make, GDB, Git, curl, wget, ripgrep, fd, and development man pages.
On Debian the `fd-find` package provides the `fdfind` command. GNU Stow links
saved configs after each package installs. Open a new shell to use `pm` from
anywhere. Keep the checkout in a stable location because the config links
point into it.

The launcher prints how to continue. Run `~/dotfiles-linux/bootstrap.sh --help`
to list bundle names and options, or use `--bundle basics --dry-run` to preview
the default setup. From the checkout, you can also choose exact packages:

```bash
./bin/pm install --dry-run vim tmux
./bin/pm install vim tmux restic
```

Bundles are plain lists in [`bundles/`](bundles/). You can combine a
bundle with individual packages, for example `./bin/pm install --bundle starter restic`.
For the full desktop and app setup, preview with
`./bootstrap.sh --bundle debian-workstation --dry-run` on Debian, or use
`--bundle arch-workstation` on Arch. Run the chosen command without `--dry-run`
from a text console after signing out of XFCE. Bootstrap installs the selected
workstation bundle and applies the saved settings.
On Debian ARM64, including a Debian VM in UTM, you can use `basics`, `starter`,
or `debian-workstation`. Bootstrap installs the compatible packages and
lists skipped packages with reasons. Dry runs show the same planned skips.

## Starter bundle

Bundles run in file order. `starter` includes the basics plus common tools,
Telegram, and Docker. A dry run on a system without Stow shows that linking is
planned. Stow can check the individual paths once it is installed. Both
workstation bundles include the basic tools. The `neovim` package installs
the distro version. Debian workstation selects `neovim-nightly` and adds the
optional `emacs-docs` package from Debian's `non-free` component.

The bundles list individual packages. Use `./bin/pm install jq fzf ffmpeg`
to select just those tools. The `bind` package maps to `bind9-dnsutils` and
`bind9-host` on Debian and `bind` on Arch.
The starter and workstation bundles include the separate `lazygit` package,
which adds the `lg` alias in Bash and Zsh. To install it on its own, run
`./bin/pm install lazygit`.

Telegram uses system Flathub. Docker uses its vendor APT source on Debian 13
and the native package on Arch. The Debian dry run shows the path to Docker's
install script.

Open a new Bash or Zsh session after installing `shell` to use `pm` from any
directory. Packages add shell fragments under `stow/.bashrc.d/` and
`stow/.zshrc.d/`. These fragments load in filename order. Shared implementation
lives outside `stow/`, in each package's `share/` directory; the fragments locate
it through their Stow symlinks.

The shell package's `00-shell.sh` fragments load `share/shell.sh` for common
PATH setup, editor defaults, aliases, and colors. `.profile` also loads the Bash
fragment for login environment setup; aliases and colors only run interactively.
Deno owns its PATH and completion setup in its own fragments and
`share/deno.sh`. Zsh loads fragments before `compinit` so packages can register
completion directories. Neovim nightly uses `~/.local/bin/nvim` and needs no
shell fragment.

The shell package also restores `.profile` for login shells. Both workstation
bundles include the pinned Deno 2.9.8 installer for Linux x86-64 and ARM64. It uses
`~/.deno/bin` and generates missing Bash and Zsh completions.

## Debian workstation packages

The `debian-workstation` bundle targets Debian 13. It starts with
the Debian source setup, then installs the recorded desktop, development,
multimedia, networking, and app packages. On ARM64 it skips Steam because
this setup uses Debian's x86 Steam launcher and 32-bit x86 graphics libraries.

The optional `imac2011` bundle restores the firmware selection
from this 27-inch iMac (`iMac12,2`), which has Intel integrated graphics and an
AMD Radeon GPU. It installs AMD, Intel, and miscellaneous firmware plus Intel
microcode. It also includes `mbpfan`, `lm-sensors`, and `smartmontools`.
The `mbpfan` package enables and starts its systemd service. Fan settings in
`/etc/mbpfan.conf` are managed separately.
The bundle also installs `imac2011-keyboard`, which swaps Fn with left Ctrl
and left Option with left Command through the Apple keyboard driver.
Right Command still triggers the keyd navigation layer. The package
updates the initramfs. Reboot to load the swaps. Its
`/etc/modprobe.d/zz-imac2011-keyboard.conf` loads after the
`hid_apple.conf` restored by Restic.
To apply just the keyboard settings, run `./bin/pm install imac2011-keyboard`.
Select the bundle when reinstalling the iMac. The model-specific packages
are skipped if the detected model differs.

Both workstation bundles install the tracked [keyd config](packages/keyd/default.conf)
to `/etc/keyd/default.conf`. It maps Caps Lock to left Ctrl and defines
the navigation layer. Run `./bin/pm install keyd` to apply it again. The
installer saves a numbered backup of a changed file and reloads keyd if
it is running.

Bootstrap applies the workstation bundle and configuration follow-ups in order.
To run just the package bundle from an existing checkout, use
`./bin/pm install --bundle debian-workstation`.

To preview both bundles together for the iMac:

```bash
./bootstrap.sh --bundle debian-workstation --bundle imac2011 --dry-run
```

Desktop restore scripts require `XDG_CONFIG_HOME` to be unset or equal to
`$HOME/.config`, matching the tracked Stow layout.

The APT setup adds missing entries for the official Debian mirrors in
`/etc/apt/sources.list.d/pm-debian.sources`. Existing `.list` and `.sources`
entries are used as coverage and left in place. A changed managed file is
backed up. Backports stays available for explicit use. Telegram is installed
via Flatpak. Steam enables the Debian `i386` architecture before installing
the required 32-bit graphics packages.

Brave, ChatGPT, and Docker use their own APT repositories. Obsidian uses its
checksummed upstream Debian package on x86-64 and Flathub on ARM64. CLIamp
uses the checksummed upstream build for the current architecture. The user
copy of yt-dlp also uses a checksummed upstream release. `neovim-nightly`
uses the checksummed nightly archive when it matches the recorded build, with a
source build from the recorded commit as a fallback. CLIamp, Neovim, and the
upstream yt-dlp copy install under `~/.local/`. Ensure `~/.local/bin` is on
your `PATH`.

See the [APT inventory](docs/debian-packages.tsv) for the original package
versions, architectures, and restore paths. Debian's installer and APT
dependencies cover the system base. The bundle installs the OpenSSH server.
See [Restore SSH from Restic](#restore-ssh-from-restic) to recover your user
keys and migrate the server's configuration and host keys.

### Back up and restore the iMac system settings

Run these from the checkout as your regular user with your initialized
repository. The workstation bundles install Restic. For a manual
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

The backup covers the Apple keyboard driver override, NetworkManager
profiles, and Samba. Older snapshots may contain a keyd config. Restore
uses the other system files and leaves keyd managed by its package. Save the repository address and Restic password somewhere
you can access after reinstalling. If the repository is on the Mac, keep a way
to connect from the fresh system, such as an SSH key available independently
of the backup. The user and server SSH backups are separate snapshots.

On fresh Debian, bootstrap prints the Restic restore command. After installing
the workstation bundle and connecting to the backup repository, run this from
the checkout:

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

### Restore SSH from Restic

List the snapshots in your SSH backup repository:

```bash
repo="$HOME/restic-debian-imac27"
restic -r "$repo" snapshots
```

For the APACER8GB USB drive, use
`repo=/media/plam/APACER8GB/restic-debian-imac27`. Add `--no-lock` to the
Restic commands if the drive is mounted read-only.

**User keys and config (`~/.ssh`)**. Choose the snapshot with your old home
directory's `.ssh` path. The example uses snapshot `fc7d4421` and path
`/home/plam/.ssh` from the iMac backup. Substitute yours if they differ and
run as your regular user:

```bash
user_stage=$(mktemp -d)
restic -r "$repo" restore fc7d4421 --target "$user_stage" &&
    mkdir -p -m 700 "$HOME/.ssh" &&
    cp -ai -- "$user_stage/home/plam/.ssh/." "$HOME/.ssh/"
```

Review any overwrite prompts. Run `ssh-add` to load standard key filenames
into your agent. For a custom filename, pass the private key path to
`ssh-add`.

**Server config and host keys (`/etc/ssh`)**. Choose the snapshot tagged
`ssh-server` with path `/etc-ssh.tar`. The iMac backup uses `f3b425a8`.
Download the archive and check its layout:

```bash
server_stage=$(mktemp -d)
restic -r "$repo" dump f3b425a8 /etc-ssh.tar > "$server_stage/etc-ssh.tar" &&
    tar -tf "$server_stage/etc-ssh.tar" | head -20
```

If the archive contains `etc/ssh/` or `/etc/ssh/`, use the commands below.
If it contains `ssh/` at the top level, use `"$server_stage/ssh/."` as the
source when copying files into `/etc/ssh/`.

```bash
sudo tar -xpf "$server_stage/etc-ssh.tar" -C "$server_stage" &&
    sudo cp -a -- /etc/ssh "$server_stage/ssh-before-restore" &&
    sudo cp -a -- "$server_stage/etc/ssh/." /etc/ssh/ &&
    sudo /usr/sbin/sshd -t &&
    sudo systemctl reload ssh
```

If you're restoring over SSH, keep your current session open and test a
second connection after the reload. The pre-restore copy is in
`"$server_stage/ssh-before-restore"`.

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
iMac firmware bundle target Debian.

## Desktop settings and fonts

Bootstrap runs the settings restores in this section for workstation bundles.
Use the commands below to apply them individually.

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

Add `--imac2011` to link the saved display, pointer, keyboard device, and
power settings for the 27-inch iMac. Stow links the desktop files, and the
restore script generates the panel XML with your home directory. On Debian,
the script also sets the GNOME color scheme to `prefer-dark` and the GTK
theme to `Adwaita-dark` for your user. Log in to XFCE after restoring the
desktop settings.

After installing `xfce4-terminal`, close XFCE Terminal and run its settings
restore from another terminal in the same desktop session:

```bash
bash packages/xfce4-terminal/post-install.sh
```

Stow links the shortcut and legacy config files. The script applies the
recorded terminal settings through Xfconf. Open XFCE Terminal afterward to
load the restored shortcuts.

## Emacs and terminal apps

Both workstation bundles link the saved Emacs init at
`~/.config/emacs/init.el`. Emacs keeps Customize changes in a separate local
`custom.el`. Emacs will use an existing legacy init under `~/.emacs`,
`~/.emacs.el`, or `~/.emacs.d/` ahead of the XDG location.

The btop, htop, and CLIamp packages link their configs under `~/.config`.
The workstation bootstrap applies them. For a manual restore, close the apps,
preview the links from the checkout, then rerun without `--dry-run`.

```bash
./bin/pm stow --dry-run btop htop cliamp
```

CLIamp restores shuffle, visualizer, equalizer, and YouTube Music preferences.
If you want private CLIamp settings, replace its config symlink with a local
copy before running `cliamp setup`. For native Brave with GNOME Keyring, the
previous setting was `cookies_from = "brave+gnomekeyring"` under `[ytmusic]`.
Keep credentials, browser cookies, listening history, and Emacs session
files out of Git.

## Existing config files

### Disable Light Locker

Install the optional config-only package to disable Light Locker autostart for
your user:

```bash
./bin/pm install disable-light-locker
```

It links `~/.config/autostart/light-locker.desktop` with `Hidden=true`.
Use this with `XDG_CONFIG_HOME` unset or equal to `~/.config`.
The change takes effect at the next login; it does not stop a running locker.

To remove the override and allow the system Light Locker autostart entry again,
run from the checkout:

```bash
./bin/pm uninstall disable-light-locker
```

Removing this override allows Light Locker to start at the next login if its
system autostart entry is installed and enabled. If installation backed up an
existing user override, that backup remains beside the original path and is
not restored automatically.

### Back up conflicting files

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

## Uninstall packages

```bash
pm uninstall --dry-run vim tmux
pm uninstall vim tmux
pm uninstall --bundle starter
```

`pm uninstall` reads the matching distro and architecture rows in `install.tsv`.
It first removes the selected packages' Stow links, leaving regular files,
unrelated symlinks, and backups intact. It then processes packages and their
install rows in reverse order, using `apt-get remove`, `pacman -R`, or system
Flatpak uninstall. Native targets and Flatpak apps that are already absent are
skipped. Removal errors stop the command; earlier removals are not rolled back.

For each script row, `pm` runs the package's optional `uninstall.sh` as your
regular user. If it is missing, `pm` prints a warning and continues with the
remaining removals. A dry run previews commands and config unlinking without
executing uninstall scripts.

Removal follows the manifest, including targets that were installed before
`pm` or are shared with other packages. There is no ownership tracking, purge,
or automatic dependency cleanup. Native package managers still enforce their
removal rules. Backups and app data such as browser profiles, Docker data,
and Steam libraries remain. The initial script uninstallers remove known
installation paths and preserve changed system config files; they do not
restore earlier backups. Shared setup such as Steam's i386 architecture,
Docker's signing key, and the upstream ChatGPT Arch repository remains.

## System preferences

The optional `system-preferences` package applies machine-wide defaults on Debian
and Arch. Its `timezone.sh` script sets the system timezone to `Europe/Madrid`.
Apply it explicitly:

```bash
./bin/pm install --dry-run system-preferences
./bin/pm install system-preferences
```

Keep separate preferences in separate scripts, listed in `install.tsv` in the
order they should run. Uninstalling this package leaves the timezone unchanged.

## Add a package

`pm add <name>` creates a commented `packages/<name>/install.tsv`. Add
tab-separated `distro`, `installer`, and `target` fields, with one target per
row. Supported installers are `apt`, `pacman`, `flatpak` (Flathub), and `script`
(a `.sh` file in the package directory, conventionally `install.sh`). Script
targets must be filenames without directory components; a package can list
multiple scripts to split setup into logical units.
Add an optional `uninstall.sh` beside `install.sh` to reverse its setup. It
should tolerate already-removed files, preserve user data, and use `sudo`
where system changes require it. No extra manifest row is needed.

One `pm` package can install multiple system packages. `pm` processes every row
for the detected distro in file order, then links the config. For example, the
`tmux` package installs `tmux` and `xclip` on both Debian and Arch. A comment-only
table with a `stow/` directory is a config-only package.

For an architecture-specific installer, add a fourth tab-separated field
with one or more comma-separated architectures as reported by `uname -m`
(for example, `x86_64,aarch64`). Rows with no fourth field apply to every
architecture. If a distro has architecture-specific rows, at least one must
match for the package to install. This lets a package select a different
installer for each architecture and share dependencies across them. Packages
with install rows and no matching distro or architecture are reported as
skipped, including their config links. For machine-specific packages, an
optional `hardware-model` file contains the exact Linux DMI product name.

Place home files under `stow/` using paths relative to `$HOME`. An optional
`post-install.sh` is listed as a manual follow-up. Bundle files contain one
package name per line, with blank lines and comments allowed. A line such as
`@base-tools` includes another bundle in place; include cycles are rejected.

See the [container test guide](tests/containers/README.md) for Debian and Arch
test environments. Keep SSH keys, browser profiles, and other private app data
in your encrypted backup.

The ChatGPT package supports Debian x86-64/ARM64 through APT and Arch through
OpenAI's installer. On Arch, the upstream installer prompts for a full system
upgrade. Use `./bin/pm install chatgpt` on either Linux distribution.

On macOS with Homebrew installed, run `bash packages/chatgpt/install.sh` from
the checkout. This package script uses the ChatGPT cask for Intel or Apple
Silicon. The repository's general bootstrap and pm commands currently target
Linux.

Install the terminal coding agent with `./bin/pm install codex`, then run
`codex` and sign in. Debian and Arch install Node.js and npm, then install
`@openai/codex` under `~/.local`. The `shell` package puts its binary on PATH.
The package skips installation when `codex` is already available. To update
this npm installation, run
`npm install --global --prefix "$HOME/.local" @openai/codex@latest`.

On macOS with Homebrew installed, run `bash packages/codex/install.sh` from
the checkout. It installs the Codex cask.
