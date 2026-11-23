# Taskwarrior

```bash
./bin/pm install --dry-run taskwarrior
./bin/pm install taskwarrior
task --version
```

On Debian 13, the installer builds the checksum-verified Taskwarrior 3.5.0
release with a temporary Rust toolchain. The build can take several minutes.
The installer places it under `~/.local/opt/taskwarrior-3.5.0` and links
`task` in `~/.local/bin`.
On Arch, pacman installs and updates the native `task` package.

Taskwarrior prompts to create its configuration and data directory on first use.
Removal preserves your tasks and configuration. On Debian, preview removal with
`./bin/pm uninstall --dry-run taskwarrior` to see which build dependencies
`pm` would remove.
