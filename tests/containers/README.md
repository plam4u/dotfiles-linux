# Disposable Debian and Arch test environments

Run these commands from the repository root on a host with Docker Engine and
Docker Compose. The official Arch image requires x86-64.

```bash
docker compose -f tests/containers/compose.yaml build --pull
docker compose -f tests/containers/compose.yaml run --rm debian
docker compose -f tests/containers/compose.yaml run --rm arch
```

Each run starts with a fresh home for `pmtest`. Both images include Bash, Git,
GNU Stow, `pm`, its packages, and passwordless `sudo` for testing package
installation. Compose mounts the current checkout read-only at `/workspace`,
where `pm` on `PATH` picks up live changes.

```bash
pm install --dry-run --bundle starter
pm install tmux vim
```

Inside the Arch container, preview the full Arch package selection with
`pm install --dry-run --bundle arch-workstation`.

For commands that write to the checkout, such as `pm add`, make a writable
copy inside the container.

```bash
cp -R /workspace "$HOME/dotfiles-linux"
cd "$HOME/dotfiles-linux"
export PATH="$PWD/bin:$PATH"
```

Use both containers to test distro detection, native package installation,
dry runs, config backups, and repeat installs. Use VMs for desktop integration
and system service startup.
