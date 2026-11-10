# Linux dotfiles with pm

`pm` installs packages and links configuration files into your home directory.
The starter packages target Debian 13 and Arch Linux. Make sure your regular
account can use `sudo` for package installs. On Arch, use a
fully updated system with synced package databases before running `pm install`.

Run the first install from the checkout. Keep the checkout in a stable location
because the config links point into it.

```bash
./bin/pm install --dry-run --bundle starter
./bin/pm install --bundle starter
```

Bundles run in file order. `starter` installs GNU Stow first, then the shell
package, common tools, tmux and its `xclip` helper, Vim, Telegram, and Docker.
It links the shell, tmux, and Vim configs. A dry run on a system without Stow
shows that linking is planned. Stow can check the individual paths once it is
installed. Both workstation bundles already include the starter packages.

`common-tools` contains utilities such as Git, `curl`, `jq`, `fzf`, and
`ffmpeg`. It has explicit APT and pacman mappings for differences such as
Debian's `bind9-dnsutils` and `bind9-host`, which Arch supplies through `bind`.
Use `./bin/pm install common-tools` to install just those utilities.

For a smaller setup, run `./bin/pm install stow shell tmux vim`. Telegram uses system
Flathub. Docker uses its vendor APT source on Debian 13 and the native package
on Arch. The Debian dry run shows the path to Docker's install script.

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

```bash
pm install --dry-run --bundle debian-workstation
bash packages/debian-apt/install.sh --dry-run
pm install --bundle debian-workstation
```

To preview both bundles together for the iMac:

```bash
pm install --dry-run --bundle debian-workstation --bundle debian-imac12-2-firmware
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

## i3 and XFCE Terminal settings

Both workstation bundles link the i3 config, its startup and scratchpad
scripts, and the three saved workspace layout files. On login, i3 launches
Flatpak Telegram and uses the available Brave install. The WhatsApp launcher
runs when its desktop entry has been restored or recreated.

After installing `xfce4-terminal`, close XFCE Terminal and run its settings
restore from another terminal in the same desktop session:

```bash
bash packages/xfce4-terminal/post-install.sh
```

The script applies the recorded terminal settings through Xfconf and copies
the shortcut and legacy config files into place, backing up files it changes.
Open XFCE Terminal afterward to load the restored shortcuts.

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
