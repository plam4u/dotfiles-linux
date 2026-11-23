# Tmux

```bash
./bin/pm install stow tmux
```

The configuration uses vi copy mode. Press `v` to select and `y` to copy;
finishing a mouse selection also copies it. The clipboard helper uses `wl-copy`
on Wayland, `xclip` on X11, and keeps only tmux's internal buffer when there is
no graphical display. Both clipboard tools are declared dependencies.

Tmux refreshes `WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR` and its default display
variables when a client attaches. Reattach from your current graphical session
when moving a persistent server between sessions. Terminal clipboard support
(OSC 52) is enabled for terminals that advertise it, including remote sessions.

Installation reloads the running tmux server for the current/default socket.
Other tmux servers can load the configuration with the prefix followed by `r`.
Existing panes and sessions are preserved, including during uninstall.
