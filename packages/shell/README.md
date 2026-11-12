# Shell configuration

```bash
./bin/pm install shell
```

Run from the repository root. The package installs Bash, Bash completion and Zsh,
and links `.bashrc`, `.zshrc` and `.profile`. Open a new shell to load them.

`00-shell.sh` loads `share/shell.sh` for common PATH setup, editor defaults,
aliases and colors. PATH includes `~/.local/bin` and this checkout's `bin`, making
`pm` available by name. `.profile` loads the Bash fragment for login environment
setup; aliases and colors only run interactively.

Shell startup loads `~/.bashrc.d/` and `~/.zshrc.d/` fragments in filename order.
Zsh loads them before `compinit` so fragments can register completion directories.
Package-owned shared implementations live outside Stow under `share/`; fragments
locate them through their Stow symlinks.
