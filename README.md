# Linux dotfiles with pm

`pm` installs packages and links configuration files into your home directory.
The starter packages target Debian 13 and Arch Linux. Make sure your regular
account can use `sudo` for package installs. On Arch, use a
fully updated system with synced package databases before running `pm install`.

From a checkout at `~/dotfiles-debian`, add its `bin` directory to your `PATH`.
Keep the checkout in a stable location because the config links point into it.

```bash
export PATH="$HOME/dotfiles-debian/bin:$PATH"
pm install --dry-run --bundle starter
pm install --bundle starter
```

Bundles run in file order. `starter` installs GNU Stow first, then tmux and its
`xclip` helper, Vim, Telegram, and Docker. It also links `.tmux.conf` and
`.vimrc`. A dry run on a system without Stow shows that linking is planned.
Stow can check the individual paths once it is installed.

For a smaller setup, run `pm install stow tmux vim`. Telegram uses system
Flathub. Docker uses its vendor APT source on Debian 13 and the native package
on Arch. The Debian dry run shows the path to Docker's install script.

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
