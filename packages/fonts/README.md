# Fonts

Installs JetBrains Mono Nerd Font, MesloLGS NF (Regular, Bold, Italic), and
MesloLGS Nerd Font Mono (Regular, Bold, Italic, Bold Italic) for the current user.
MesloLGS Nerd Font Mono is used by Obsidian.

```bash
./bin/pm install fonts
```

Fonts are installed under `${XDG_DATA_HOME:-$HOME/.local/share}/fonts`, and the
font cache is refreshed automatically. Reopen running apps if the new family
does not appear in their font picker.

Nerd Fonts archives are pinned to v3.5.1 and verified with SHA-256 checksums.
Uninstall removes the font files installed by this package and refreshes the cache.
