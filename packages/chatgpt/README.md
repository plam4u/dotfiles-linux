# ChatGPT desktop application

```bash
./bin/pm install chatgpt
```

Run from the repository root. Debian x86-64 and ARM64 use the vendor APT source.
Arch uses OpenAI's installer, which configures its signed repository and prompts
for a full system upgrade. Uninstall leaves the upstream Arch repository in
place.

On macOS with Homebrew already installed, run
`bash packages/chatgpt/install.sh` to install the cask on Intel or Apple Silicon.
The repository's `pm` and bootstrap commands target Linux.
