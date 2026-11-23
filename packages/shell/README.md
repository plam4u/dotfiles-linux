# Shell configuration

```bash
./bin/pm install shell
```

Run from the repository root. The package installs Bash, Bash completion and Zsh,
and links `.bashrc`, `.zshrc` and `.profile`. Open a new shell to load them.

On Omarchy, Bash also loads the packaged environment and default Bash rc,
preserving Omarchy aliases, functions, prompt and development tool setup.
Package fragments load afterward so repository aliases take precedence over
Omarchy defaults. Personal `~/.bash_aliases` overrides load last.

`00-shell.sh` resolves the checkout location through its Stow symlink and exports
`DOTFILES_ROOT`, then loads `share/shell.sh` for common PATH setup, editor defaults,
aliases and colors. PATH includes `~/.local/bin` and this checkout's `bin`, making
`pm` available by name. `.profile` loads the Bash fragment for login environment
setup; aliases and colors only run interactively.

Shell startup loads `~/.bashrc.d/` and `~/.zshrc.d/` fragments in filename order.
Zsh loads them before `compinit` so fragments can register completion directories.
Package-owned shared implementations live outside Stow under `share/`. After
`00-shell.sh` initializes `DOTFILES_ROOT`, fragments source them directly, for
example `. "$DOTFILES_ROOT/packages/tree/share/tree.sh"`. When using your own
shell startup configuration, export `DOTFILES_ROOT` to the checkout's absolute
path before loading package fragments.
