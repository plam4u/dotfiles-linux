# Docker

```bash
./bin/pm install docker
```

Run from the repository root. Debian 13 uses Docker's vendor APT repository.
Arch uses its native Docker, Buildx and Compose packages. The Debian dry run
shows the installer script path.

Start Docker when you want to use it:

```bash
sudo systemctl enable --now docker.service
```

Uninstall preserves Docker data and the Debian signing key at
`/etc/apt/keyrings/docker.asc`.
