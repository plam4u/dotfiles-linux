# Linux dotfiles with pm

`pm` installs Linux packages and links configuration into your home directory
with GNU Stow. Supported systems are Debian 13 on x86-64 or ARM64 and Arch Linux
on x86-64. Run commands as your regular user with `sudo` access.

## Quick start

```bash
wget -O- https://github.com/plam4u/dotfiles-linux/raw/main/install.sh | bash
~/dotfiles-linux/bootstrap.sh
```

You can use `curl -fsSL` in place of `wget -O-`. The installer installs Git if
needed and clones the repository to `~/dotfiles-linux`. Bootstrap installs the
[basics bundle](bundles/basics). Keep the checkout in a stable location because
configuration symlinks point into it.

From the checkout, preview installation before applying it:

```bash
./bin/pm install --dry-run vim tmux
./bin/pm install vim tmux
```

GNU Stow is required for configuration linking. On a minimal system, install it
first with `./bin/pm install stow`, or list `stow` before packages with saved
configuration. Bundles include it in their setup order.

Package configuration and required follow-up steps are documented in each
package's README; `pm install` prints its path when available.
See the [package guide](#package-guide). Installing one package
does not imply that an unrelated package or bundle is installed.

## Bundles and bootstrap

Bundles are ordered package lists in [bundles/](bundles/). A line such as
`@base-tools` includes another bundle. Repeated packages run once.

| Bundle | Purpose |
| --- | --- |
| [basics](bundles/basics) | Default command-line tools and configuration |
| [starter](bundles/starter) | Basics plus additional tools and applications |
| [debian-workstation](bundles/debian-workstation) | Debian desktop and application setup |
| [arch-workstation](bundles/arch-workstation) | Arch desktop and application setup |
| [imac2011](bundles/imac2011) | Debian iMac hardware selection and system preferences |

The [Debian inventory](docs/debian-packages.tsv) records the original package
versions and architectures.

```bash
./bootstrap.sh --help
./bootstrap.sh --bundle debian-workstation --dry-run
./bootstrap.sh --bundle arch-workstation --dry-run
./bootstrap.sh --bundle debian-workstation --bundle imac2011 --dry-run
```

Choose the workstation bundle for your distribution. To apply it, sign out of
the graphical session, switch to a text console and rerun without `--dry-run`.
Bootstrap installs the bundle and runs the coordinated desktop restore steps.
Desktop restore scripts require `XDG_CONFIG_HOME` to be unset or equal to
`$HOME/.config`. Sign in again or reboot afterward.

You can combine bundles and individual packages:

```bash
./bin/pm install --bundle starter jq
```

`pm` reports packages skipped for an unsupported distribution, architecture or
hardware model. Dry runs show the same planned skips. Debian ARM64 systems,
including VMs, can use `basics`, `starter` or `debian-workstation`.

Private settings are not restored automatically. After reinstalling, complete
SSH recovery using the [Restic package instructions](packages/restic/README.md).

## Package guide

Run the documented package commands from the repository root. Packages without
a README can be inspected through their `install.tsv` and configuration files
in [packages/](packages/).

| Package | Instructions |
| --- | --- |
| chatgpt | [Desktop application](packages/chatgpt/README.md) |
| cliamp | [Player configuration and private settings](packages/cliamp/README.md) |
| codex | [Terminal agent installation and sign-in](packages/codex/README.md) |
| docker | [Installation and service startup](packages/docker/README.md) |
| restic | [Private SSH recovery](packages/restic/README.md) |
| samba | [File sharing and account setup](packages/samba/README.md) |
| shell | [Shell startup and PATH](packages/shell/README.md) |
| steam | [Installation requirements](packages/steam/README.md) |
| system-preferences | [Keyboard, timezone and appearance](packages/system-preferences/README.md) |
| xfce4 | [Desktop restore](packages/xfce4/README.md) |
| xfce4-terminal | [Terminal settings restore](packages/xfce4-terminal/README.md) |

## Configuration linking and backups

`pm install` installs dependencies and scripts before linking a package's
configuration. `pm stow` runs only the linking step:

```bash
./bin/pm stow --dry-run tmux vim
./bin/pm stow tmux vim
```

Conflicting regular files are saved beside the originals with `.bak`, then
`.bak.1`, `.bak.2` and so on. `pm` prints each backup path. Review directory
conflicts and unrelated symlinks manually. GNU Stow uses per-file links and
package-local ignore rules, independently of personal Stow settings.

## Uninstall packages

```bash
./bin/pm uninstall --dry-run vim tmux
./bin/pm uninstall vim tmux
./bin/pm uninstall --bundle starter
```

Uninstall first removes selected Stow links, leaving regular files, unrelated
symlinks and backups intact. It processes packages in reverse order, running
each package's optional `uninstall.sh` once before removing its manifest
packages in reverse order. Missing uninstall scripts produce a warning; already
absent native packages and Flatpak applications are skipped. Errors stop the
command, without rolling back earlier removals.

Removal follows the manifest, including dependencies installed before `pm` or
shared with other packages. There is no ownership tracking, purge or automatic
dependency cleanup. Package managers still enforce their removal rules. Backup
files are not restored automatically. Package-specific cleanup and retained
application data are described in the owning package's documentation.

## Add a package

```bash
./bin/pm add example
```

This creates `packages/example/install.tsv`. Use literal tabs between `distro`,
`installer` and `target`, with an optional fourth architecture field. Supported
installers are `apt`, `pacman`, `flatpak` for system Flathub, and `script` for a
package-local `.sh` file. Script targets are filenames without directory
components; multiple scripts can split setup into logical units.

Declare each package's dependencies before scripts that use them. Packages must
install independently of bundles and other repository packages; do not rely on
an earlier bundle entry to supply a required tool. See [AGENTS.md](AGENTS.md)
for the package independence, documentation and simplicity rules.

Each matching row runs in file order, then configuration is linked. A
comment-only manifest with a `stow/` directory is a config-only package.
Place home files under `stow/`, relative to `$HOME`. Shared package-owned shell
code belongs in `share/`, outside the Stow tree.

Architecture fields use comma-separated `uname -m` values such as
`x86_64,aarch64`; an omitted field applies to all architectures. A package with
architecture-specific rows for the selected distribution needs at least one
match. Unsupported packages are skipped along with their configuration links.
An optional `hardware-model` file specifies the exact Linux DMI product name.

Add an optional `uninstall.sh` to reverse managed setup. It runs as the regular
user and should preserve edited files and user data, using `sudo` where needed.
An optional `post-install.sh` is printed as a manual follow-up. Put detailed
setup instructions and follow-up explanations in the package's `README.md`.

See the [container test guide](tests/containers/README.md) for disposable Debian
and Arch environments. Keep credentials, private keys and private application
state out of Git.
