# CLIamp

```bash
./bin/pm install cliamp
```

Run from the repository root. The installer uses a checksum-verified upstream
binary for Linux x86-64 or ARM64 under `~/.local/bin`. Run `~/.local/bin/cliamp`
directly or add `~/.local/bin` to your PATH.

The package links `~/.config/cliamp/config.toml` with shuffle, visualizer,
equalizer and YouTube Music preferences. Close CLIamp before restoring its
configuration; preview the links with `./bin/pm stow --dry-run cliamp`.

For private settings, replace the config symlink with a local copy before
running `cliamp setup`. Keep credentials, browser cookies and listening history
out of Git.
