# Vim

```bash
./bin/pm install --dry-run vim
./bin/pm install vim
```

Visual-mode `y` also copies to the system clipboard:
`wl-copy` on Wayland, or `xclip` on X11. Routing lives in the Stowed `~/.local/bin/vim-copy` command, which reads stdin.
Both tools are installed as dependencies on
Debian and Arch/Omarchy. This works without Vim's optional `+clipboard` support.
Normal-mode yanks, deletes and changes keep Vim's normal behavior.
Without a graphical display, yanks only update Vim's registers.

Restart Vim or run `:source ~/.vimrc` to load configuration changes.
