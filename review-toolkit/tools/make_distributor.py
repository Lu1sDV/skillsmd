#!/usr/bin/env python3
"""Build a reproducible ZIP and self-extracting Python distributor from skillsmd/."""
from __future__ import annotations

import argparse
import base64
import hashlib
import io
import textwrap
import zipfile
from pathlib import Path

import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from tools.build_skills import generated_skills
OUT = ROOT.parent
SKIP = {"__pycache__", ".pytest_cache", ".DS_Store", ".git"}


def package_bytes(root: Path = ROOT) -> bytes:
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zipf:
        files = (p for p in root.rglob("*") if p.is_file() and not any(part in SKIP for part in p.parts)
                 and p.suffix not in {".pyc", ".pyo"} and p.name != "IN_REPO.md")
        for path in sorted(files, key=lambda p: p.relative_to(root).as_posix()):
            rel = path.relative_to(root).as_posix()
            info = zipfile.ZipInfo("skillsmd/" + rel, date_time=(2026, 11, 4, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = (0o100644 << 16)
            zipf.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
        # Generated standalone skill files are part of distribution, not extra
        # SKILL.md registrations inside the mono-repo.
        for rel, content in sorted(generated_skills(root).items()):
            info = zipfile.ZipInfo("skillsmd/" + rel, date_time=(2026, 11, 4, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = (0o100644 << 16)
            zipf.writestr(info, content, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    return buf.getvalue()


def render_distributor(archive: bytes) -> str:
    payload = base64.b85encode(archive).decode("ascii")
    chunks = "\n".join('    "' + payload[i:i+96] + '"' for i in range(0, len(payload), 96))
    digest = hashlib.sha256(archive).hexdigest()
    prefix = '''#!/usr/bin/env python3
"""Portable v2 review skill installer. Python 3.9+ standard library only.

  python3 review-tools-install.py extract skillsmd
  python3 review-tools-install.py install --target all --with-reviewer --dry-run
  python3 review-tools-install.py upgrade --target all --with-reviewer
  python3 review-tools-install.py check-compat --target all
"""
from __future__ import annotations

import base64
import hashlib
import io
import pathlib
import subprocess
import sys
import tempfile
import zipfile

SHA256 = "@@HASH@@"
PAYLOAD = (
@@PAYLOAD@@
)


def extract(target: pathlib.Path) -> None:
    raw = base64.b85decode(PAYLOAD)
    if hashlib.sha256(raw).hexdigest() != SHA256:
        raise RuntimeError("Embedded package hash mismatch")
    target = target.expanduser().absolute()
    if target.is_symlink() or (target.exists() and not target.is_dir()):
        raise RuntimeError(f"Refusing unsafe extraction directory: {target}")
    if target.exists() and any(target.iterdir()):
        raise RuntimeError(f"Extraction directory is not empty: {target}; choose a new directory to preserve edits")
    with zipfile.ZipFile(io.BytesIO(raw)) as source:
        members = source.infolist()
        for member in members:
            parts = pathlib.PurePosixPath(member.filename).parts
            if not parts or parts[0] != "skillsmd" or any(p in ("..", "") for p in parts):
                raise RuntimeError(f"Unexpected archive path: {member.filename}")
            if (member.external_attr >> 16) & 0o170000 == 0o120000:
                raise RuntimeError("Refusing symlink archive entry")
            rel = pathlib.Path(*parts[1:])
            dest = target / rel
            if dest.exists() and dest.is_symlink():
                raise RuntimeError(f"Refusing symlink destination: {dest}")
            for folder in (target, *dest.parents):
                if folder.is_symlink():
                    raise RuntimeError(f"Refusing symlinked ancestor: {folder}")
            if member.is_dir():
                dest.mkdir(parents=True, exist_ok=True)
                continue
            if not rel.parts:
                raise RuntimeError("Unexpected empty archive entry")
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(source.read(member))


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__.strip())
        return 2
    action, *arguments = sys.argv[1:]
    if action == "extract":
        if len(arguments) > 1:
            print("Usage: review-tools-install.py extract [skillsmd-directory]", file=sys.stderr)
            return 2
        where = pathlib.Path(arguments[0]) if arguments else pathlib.Path("skillsmd")
        extract(where)
        print(f"EXTRACTED {where.absolute()}")
        return 0
    mapping = {
        "install": ("install.py", "install"),
        "upgrade": ("install.py", "upgrade"),
        "check-compat": ("tools/check_harnesses.py",),
        "review-plan": ("tools/review_plan.py",),
    }
    if action not in mapping:
        print(f"Unknown action: {action}", file=sys.stderr)
        return 2
    with tempfile.TemporaryDirectory(prefix="review-tools-") as temporary:
        root = pathlib.Path(temporary) / "skillsmd"
        extract(root)
        script, *first_args = mapping[action]
        return subprocess.run([sys.executable, str(root / script), *first_args, *arguments], check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
'''
    return prefix.replace("@@HASH@@", digest).replace("@@PAYLOAD@@", chunks)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Assert distributor and ZIP match source")
    args = parser.parse_args()
    archive = package_bytes()
    standalone = render_distributor(archive).encode("utf-8")
    deliverables = {OUT / "review-tools-v2.zip": archive, OUT / "review-tools-install.py": standalone}
    for path, content in deliverables.items():
        if args.check:
            if not path.is_file() or path.read_bytes() != content:
                print(f"STALE {path}")
                return 1
        else:
            path.write_bytes(content)
            print(f"BUILT {path.name} {len(content)} bytes sha256={hashlib.sha256(content).hexdigest()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
