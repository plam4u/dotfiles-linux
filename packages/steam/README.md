# Steam

```bash
./bin/pm install steam
```

Run from the repository root. Steam is supported on x86-64.

On Debian, the installer enables the `i386` architecture, ensures Debian APT
source coverage, and installs the launcher and required 32-bit graphics
libraries. Debian ARM64 is skipped.

On Arch, enable `multilib` and fully update the system before installing Steam.

Uninstall keeps Steam libraries, the Debian `i386` architecture and shared
Debian sources.
