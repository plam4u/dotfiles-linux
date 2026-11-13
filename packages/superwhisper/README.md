# Superwhisper

Install with `./bin/pm install superwhisper`; link settings only with
`./bin/pm stow superwhisper`.

Debian 13 uses the official 1.3.1 release, pinned by SHA-256 for x86-64 and ARM64.
The vendor installer installs runtime dependencies and starts/enables its user
service and update timer. Subsequent vendor updates are managed upstream.
Arch uses the `superwhisper-bin` package from the configured repositories
(available on Omarchy).

Requires a Wayland desktop and systemd user session. Sign in through Superwhisper
for cloud use; download offline models through its settings when desired.

Stowed files preserve current preferences (Ctrl+Alt+Space recording toggle,
Escape cancellation, launch at login) and vocabulary (Omarchy, Superwhisper).
Credentials, device identifiers, usage, history, models, generated shortcuts,
and backup files are deliberately excluded. Change settings through the
Superwhisper CLI or settings window.
