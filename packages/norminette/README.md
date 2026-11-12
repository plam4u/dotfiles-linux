# Norminette for 42

Install the [official 42 Norminette](https://github.com/42school/norminette)
locally on Debian 13 or Arch:

```bash
./bin/pm install --dry-run norminette
./bin/pm install norminette
```

The package installs pipx and setuptools, then installs Norminette in an
isolated Python environment for your user. It configures the pipx command
directory on PATH; open a new terminal if needed after installation.

Run it from a project directory to check C source and header files recursively,
or pass individual files:

```bash
norminette
norminette main.c includes/example.h
```

Update the local installation with `pipx upgrade norminette`. To match a
specific version used on campus, use `pipx install --force 'norminette==VERSION'`
with that version number.

Remove it with `./bin/pm uninstall norminette`. The uninstaller removes only
Norminette's pipx environment; other pipx applications and your source files
are preserved. As with other repository packages, `pm` also removes the
dependencies listed in the manifest.
