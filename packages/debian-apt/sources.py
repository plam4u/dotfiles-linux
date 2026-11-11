"""Add only the official Debian source entries missing from this workstation."""

import argparse
from pathlib import Path
import re
import subprocess
from tempfile import TemporaryDirectory
from typing import NamedTuple
from urllib.parse import urlsplit


MANAGED = "# Managed by pm (debian-apt)\n"
ARCHIVE_KEY = "/usr/share/keyrings/debian-archive-keyring.gpg"
DEBIAN = "https://deb.debian.org/debian"
SECURITY = "https://security.debian.org/debian-security"


class Source(NamedTuple):
    kind: str
    uri: str
    suite: str
    components: tuple[str, ...]
    signed_by: str
    architectures: frozenset[str] | None = None


def source_architectures(options, defaults):
    """Apply APT architecture selection options to the configured defaults."""
    selected = set(options.get("architectures", defaults))
    selected.update(options.get("architectures-add", ()))
    selected.difference_update(options.get("architectures-remove", ()))
    return frozenset(selected)


def official_archive(uri):
    url = urlsplit(uri)
    path = url.path.rstrip("/")
    if url.scheme not in {"http", "https"}:
        return None
    if url.hostname == "deb.debian.org" and path == "/debian":
        return DEBIAN
    if url.hostname in {"security.debian.org", "deb.debian.org"} and path == "/debian-security":
        return SECURITY
    return None


def read_sources(path, architectures=("amd64",)):
    content = path.read_text()
    if path.suffix == ".list":
        for line in content.splitlines():
            match = re.fullmatch(
                r"\s*(deb(?:-src)?)\s+(?:\[([^\]]*)\]\s+)?(\S+)\s+(\S+)\s+(.+)",
                line.partition("#")[0],
            )
            if match:
                kind, options, uri, suite, components = match.groups()
                key = re.search(r"(?:^|\s)signed-by=(\S+)", options or "")
                arch_options = {}
                for option, value in re.findall(r"(?:^|\s)arch([+-]?)=([^\s]+)", options or ""):
                    field = {"": "architectures", "+": "architectures-add", "-": "architectures-remove"}[option]
                    arch_options[field] = value.split(",")
                yield Source(kind, uri, suite, tuple(components.split()), key[1] if key else "",
                             source_architectures(arch_options, architectures))
        return

    for stanza in re.split(r"\n[ \t]*\n", content):
        fields = {}
        name = None
        for line in stanza.splitlines():
            if not line or line.startswith("#"):
                continue
            if line[0].isspace() and name:
                fields[name] += "\n" + line
            else:
                name, _, value = line.partition(":")
                name = name.lower()
                fields[name] = value.strip()
        if fields.get("enabled", "yes").lower() == "no":
            continue
        selected_architectures = source_architectures(
            {name: fields[name].split() for name in
             ("architectures", "architectures-add", "architectures-remove") if name in fields},
            architectures,
        )
        components = tuple(fields.get("components", "").split())
        for uri in fields.get("uris", "").split():
            for suite in fields.get("suites", "").split():
                for kind in fields.get("types", "").split():
                    yield Source(kind, uri, suite, components, fields.get("signed-by", ""), selected_architectures)


def missing_sources(existing, architectures=("amd64",)):
    for archive, suite, kinds in (
        (DEBIAN, "trixie", ("deb", "deb-src")),
        (DEBIAN, "trixie-updates", ("deb", "deb-src")),
        (SECURITY, "trixie-security", ("deb", "deb-src")),
        (DEBIAN, "trixie-backports", ("deb",)),
    ):
        matches = [s for s in existing if s.suite == suite and official_archive(s.uri) == archive]
        # APT requires sources sharing a URI and suite to agree on Signed-By.
        uri, key = (matches[0].uri, matches[0].signed_by) if matches else (archive, ARCHIVE_KEY)
        for kind in kinds:
            desired = ("main", "non-free-firmware")
            if suite == "trixie" and kind == "deb":
                desired = ("main", "contrib", "non-free", "non-free-firmware")
            elif suite == "trixie-backports":
                desired = ("main",)
            # Source indexes are architecture independent. Binary indexes are not.
            groups = (None,) if kind == "deb-src" else architectures
            for architecture in groups:
                covered = {component for s in matches if s.kind == kind
                           and (architecture is None or s.architectures is None
                                or architecture in s.architectures)
                           for component in s.components}
                missing = [component for component in desired if component not in covered]
                if missing:
                    yield (f"Types: {kind}\nURIs: {uri}\nSuites: {suite}\n"
                           f"Components: {' '.join(missing)}\n"
                           + (f"Architectures: {architecture}\n" if architecture else "")
                           + (f"Signed-By: {key}\n" if key else ""))



def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    architectures = tuple(subprocess.check_output(
        ["dpkg", "--print-architecture"], text=True).split() + subprocess.check_output(
        ["dpkg", "--print-foreign-architectures"], text=True).split())
    apt_dir = Path("/etc/apt")
    source_dir = apt_dir / "sources.list.d"
    target = source_dir / "pm-debian.sources"
    paths = [apt_dir / "sources.list", *sorted(source_dir.glob("*.list")),
             *sorted(source_dir.glob("*.sources"))]
    sources = [source for path in paths if path != target and path.is_file()
               for source in read_sources(path, architectures)]
    old = target.read_text() if target.is_file() else ""
    if target.is_symlink() or (target.exists() and not old.startswith(MANAGED)):
        parser.exit(1, f"Review the existing file at {target} before retrying.\n")
    additions = list(missing_sources(sources, architectures))
    content = MANAGED + "\n".join(additions)
    if content == old or (not additions and not old):
        print("Debian sources already cover the workstation components and suites.")
        return

    if args.dry_run:
        print(f"Would write {target}:\n{content}", end="")
        return

    with TemporaryDirectory(prefix="pm-debian-apt-") as temp:
        staged = Path(temp) / target.name
        staged.write_text(content)
        if old:
            subprocess.run(["sudo", "cp", "--preserve=mode,ownership,timestamps",
                            "--backup=numbered", "--", str(target), f"{target}.bak"], check=True)
        subprocess.run(["sudo", "install", "-m", "0644", "--", str(staged), str(target)], check=True)
    subprocess.run(["sudo", "apt-get", "update"], check=True)


if __name__ == "__main__":
    main()
