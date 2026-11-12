# Repository Guidelines

## Project Structure & Module Organization

This repository manages Linux packages and dotfiles for Debian 13 and Arch.
`bin/pm` implements package planning, installation, removal, and GNU Stow linking.
`bootstrap.sh` selects bundles; `install.sh` handles initial checkout setup.

- `packages/<name>/`: tab-separated `install.tsv`, optional installation/removal scripts, and configuration assets.
- `packages/<name>/stow/`: files arranged relative to `$HOME`.
- `packages/<name>/share/`: package-owned code shared by shell fragments.
- `share/`: reusable installer and uninstaller helpers.
- `bundles/`: ordered package lists; `@name` includes another bundle.
- `tests/unit/`: Python regression tests; `tests/containers/`: disposable distro environments.

## Build, Test, and Development Commands

There is no compilation step for the package manager. Run commands from the repository root:

- `./bin/pm install --dry-run vim tmux`: preview installation and configuration linking.
- `./bin/pm stow --dry-run shell deno`: preview configuration changes only.
- `./bin/pm add <name>`: scaffold a package manifest.
- `python3 -B -m unittest discover -s tests/unit -v`: run the regression suite.
- `bash -n bin/pm`: check Bash syntax; also check changed scripts with their intended shell.
- `docker compose -f tests/containers/compose.yaml build --pull`: build test images; use `run --rm debian` or `run --rm arch` with the same Compose file to test installations.

## Coding Style & Naming Conventions

Correctness comes first; simplicity comes next. This is a personal-use repository: once a package installs and Stows its intended configuration correctly, prefer the simplest implementation. Add complexity only for required behavior or concrete safety needs. Avoid guards and abstractions for harmless cases, such as defining aliases in non-interactive shells.

Do not add legacy file handling, migration code, backward-compatibility shims, or fallbacks for retired package layouts unless explicitly requested. When renaming or moving configuration, update the current scripts, manifests, documentation, and relevant tests directly. Do not detect, migrate, rename, or clean up old paths, and do not add tests for those paths. Preserve user data and normal configuration backups without building migration machinery.

Use four-space indentation in shell and Python code. Follow existing Bash conventions: quote paths, use local function variables, and use `set -euo pipefail` in standalone installers. Manifests require literal tabs, not spaces. Prefer lowercase, hyphenated package names.

Keep package-specific shell integration in its own `stow/.bashrc.d/` and `stow/.zshrc.d/` fragments. Put shared implementation outside `stow/`, under the owning package's `share/`; avoid adding fragment directories. Keep generic shell setup independent of specific packages. No repository-wide formatter is configured.

## Testing Guidelines

Use Python `unittest`, with `test_*.py` files and `test_*` methods. Test meaningful regressions using temporary homes, real Stow, and mocked package managers. Run as a regular user; uninstall tests skip root. Exercise repeated sourcing and both Bash and Zsh when changing shared shell setup. No numeric coverage threshold is configured.

## Commit & Pull Request Guidelines

Follow the history's short, imperative subjects, such as “Add package uninstall support” or “Fix installer edge cases.” Keep commits focused. PR descriptions should explain behavior changes, affected distributions, and validation performed. Link relevant issues and update README instructions when workflows change.

## Configuration Safety

Preview installation and removal before changing the host. Preserve user data and numbered configuration backups. Keep credentials, browser profiles, cookies, and other private application state out of Git. Verify downloaded binaries with pinned checksums.
