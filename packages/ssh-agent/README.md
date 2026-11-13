# SSH agent

Install from a desktop session as your regular user:

```bash
./bin/pm install --dry-run ssh-agent
./bin/pm install ssh-agent
```

Included in the Debian and Omarchy workstation bundles. Installs GCR's SSH agent,
OpenSSH client tools, GNOME Keyring and user D-Bus support. Installation enables
and starts the systemd user socket; the agent starts on demand. No per-terminal
agent processes are launched. Uninstall disables the socket and stops the agent.

Stow links `~/.config/environment.d/90-gcr-ssh-agent.conf` for desktop applications
and Bash/Zsh fragments for shell sessions. Shell fragments preserve an existing
`SSH_AUTH_SOCK`, including forwarded agents, and require a shell setup that loads
`~/.bashrc.d/` or `~/.zshrc.d/` (provided by the shell package).

Log out and back in after installation so every application inherits the socket.
Existing terminals can use it immediately with:

```bash
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
```

Encrypted keys prompt graphically on first use, with an option to remember the
passphrase in the keyring. Key creation, passphrases and authentication require
user input; private keys are never stored in this repository. This package does
not configure desktop PAM keyring unlocking. Installing it requires a running
systemd user session; graphical prompts require a desktop session.
