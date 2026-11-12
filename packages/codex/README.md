# Codex terminal agent

```bash
./bin/pm install codex
```

Run from the repository root. Debian and Arch install Node.js and npm before
installing `@openai/codex` under `~/.local`. Run `~/.local/bin/codex` to sign in,
or add `~/.local/bin` to your PATH to invoke `codex` by name. Installation skips
when a `codex` executable is already available.

Update this npm installation with:

```bash
npm install --global --prefix "$HOME/.local" @openai/codex@latest
```

On macOS with Homebrew already installed, run
`bash packages/codex/install.sh` to install the cask. The repository's `pm` and
bootstrap commands target Linux.
