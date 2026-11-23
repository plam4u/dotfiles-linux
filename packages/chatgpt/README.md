# ChatGPT desktop application

```bash
./bin/pm install chatgpt
```

Run from the repository root. Debian x86-64 and ARM64 use the vendor APT source.
Arch uses OpenAI's installer, which configures its signed repository and prompts
for a full system upgrade. Uninstall leaves the upstream Arch repository in
place.

On Omarchy, installation sets `~/.config/codex-flags.conf` (or the directory in
`XDG_CONFIG_HOME`) to disable GPU acceleration and use X11 through XWayland:

```text
--disable-gpu
--ozone-platform=x11
```

These defaults apply to both `chatgpt` and the desktop launcher. Reinstalling the
dotfiles package reapplies them, preserving changed configuration in numbered
backups. Fully quit and reopen the app after changing the flags.

On macOS with Homebrew already installed, run
`bash packages/chatgpt/install.sh` to install the cask on Intel or Apple Silicon.
The repository's `pm` and bootstrap commands target Linux.
