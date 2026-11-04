#!/usr/bin/env python3
"""Safe, source-driven installer/upgrader for pi, omp, Codex and Claude Code.

Install and upgrade both compile canonical src/shared policy in memory, so edits to
source files propagate without manually running build_skills.py. Version pin
checks are separate and opt-in: see tools/check_harnesses.py.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sys
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
from tools.build_skills import generated_skills  # noqa: E402

TARGETS = ("pi", "omp", "codex", "claude-code")
MANIFEST_NAME = ".review-tools-manifest.json"
SCHEMA_VERSION = 2


def sha(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def sha_file(path: Path) -> str:
    return sha(path.read_bytes())


@dataclass(frozen=True)
class Roots:
    target: str
    scope: str
    base: Path
    skill_base: Path

    def resolve(self, key: str) -> Path:
        if key.startswith("skills/"):
            return self.skill_base / key
        return self.base / key

    @property
    def manifest(self) -> Path:
        return self.base / MANIFEST_NAME


def root_paths(target: str, scope: str = "user", project_root: Path | None = None,
               home: Path | None = None) -> Roots:
    if target not in TARGETS:
        raise ValueError(f"Unknown target: {target}")
    if scope not in {"project", "user"}:
        raise ValueError("Scope must be user or project")
    h = (home or Path.home()).expanduser().absolute()
    if scope == "project":
        p = (project_root or Path.cwd()).expanduser().absolute()
        if target == "codex":
            return Roots(target, scope, p / ".codex", p / ".agents")
        name = {"pi": ".pi", "omp": ".omp", "claude-code": ".claude"}[target]
        return Roots(target, scope, p / name, p / name)
    if target == "pi":
        base = Path(os.environ.get("PI_CODING_AGENT_DIR", h / ".pi" / "agent")).expanduser().absolute() if home is None else h / ".pi" / "agent"
        return Roots(target, scope, base, base)
    if target == "omp":
        base = h / ".omp" / "agent"
        return Roots(target, scope, base, base)
    if target == "codex":
        return Roots(target, scope, h / ".codex", h / ".agents")
    return Roots(target, scope, h / ".claude", h / ".claude")


def layout_for(target: str, with_reviewer: bool = False, scope: str = "user") -> dict[str, bytes]:
    if target not in TARGETS:
        raise ValueError(target)
    contents = generated_skills(ROOT).copy()
    def from_file(group: str, name: str) -> bytes:
        return (ROOT / "harnesses" / group / name).read_bytes()
    for name in ("review-code", "review-pr"):
        if target == "pi":
            contents[f"prompts/{name}.md"] = from_file("pi", f"{name}.md")
        elif target == "omp":
            contents[f"commands/{name}.md"] = from_file("omp", f"{name}.md")
        elif target == "codex" and scope == "user":
            # Legacy namespaced prompts; native $skills are preferred. Codex prompts
            # are only discovered from the user's Codex config root.
            contents[f"prompts/{name}.md"] = from_file("codex", f"{name}.md")
    if with_reviewer:
        if target == "pi":
            contents["agents/reviewer.md"] = from_file("pi", "reviewer.md")
        elif target == "claude-code":
            contents["agents/reviewer.md"] = from_file("claude", "reviewer.md")
        elif target == "codex":
            contents["agents/reviewer.toml"] = from_file("codex", "reviewer.toml")
        # OMP ships a reviewer role; do not override its native definition.
    return contents


def valid_keys(target: str, scope: str) -> set[str]:
    return set(layout_for(target, with_reviewer=True, scope=scope)) | set(layout_for(target, with_reviewer=True, scope="user"))


def read_manifest(roots: Roots) -> dict[str, str]:
    file = roots.manifest
    if not file.exists() and not file.is_symlink():
        return {}
    if file.is_symlink():
        raise ValueError(f"Refusing manifest symlink: {file}")
    doc = json.loads(file.read_text(encoding="utf-8"))
    if doc.get("schema_version") != SCHEMA_VERSION or doc.get("target") != roots.target or doc.get("scope") != roots.scope:
        raise ValueError(f"Unrecognized manifest; do not overwrite: {file}")
    entries = doc.get("entries")
    if not isinstance(entries, dict):
        raise ValueError(f"Invalid manifest entries: {file}")
    unknown = set(entries) - valid_keys(roots.target, roots.scope)
    if unknown:
        raise ValueError(f"Manifest has unknown/untrusted paths: {', '.join(sorted(unknown))}")
    if not all(isinstance(v, str) and len(v) == 64 and all(x in "0123456789abcdef" for x in v) for v in entries.values()):
        raise ValueError(f"Invalid manifest hashes: {file}")
    return entries


def verify_safe(path: Path, root: Path) -> None:
    """Reject symlinked destinations/parents, including manifest root itself."""
    path = path.absolute()
    root = root.absolute()
    try:
        rel = path.relative_to(root)
    except ValueError as exc:
        raise ValueError(f"Destination escaped target root: {path} != {root}") from exc
    if root.is_symlink():
        raise ValueError(f"Refusing symlinked root {root}")
    check = root
    for fragment in rel.parts:
        check = check / fragment
        if check.is_symlink():
            raise ValueError(f"Refusing symlinked destination or parent {check}")
    if root.exists() and not root.is_dir():
        raise ValueError(f"Destination root is not a directory: {root}")
    if path.exists() and path.is_dir():
        raise ValueError(f"Destination is a directory, not a file: {path}")


def safe_path(roots: Roots, key: str) -> Path:
    # Disallow traversal and unknown keys even in an untrusted manifest.
    if key not in valid_keys(roots.target, roots.scope):
        raise ValueError(f"Untrusted installation path: {key}")
    p = roots.resolve(key)
    root = roots.skill_base if key.startswith("skills/") else roots.base
    verify_safe(p, root)
    return p


@dataclass(frozen=True)
class Operation:
    key: str
    action: str  # write, delete, unchanged, preserve
    path: Path
    content: bytes | None
    backup: bool = False


def plan_changes(roots: Roots, *, with_reviewer: bool, force: bool) -> tuple[list[Operation], list[str], dict[str, str]]:
    previous = read_manifest(roots)
    desired = layout_for(roots.target, with_reviewer, scope=roots.scope)
    # Optional reviewer definitions are kept when an upgrade omits the flag.
    # Preserve the PRIOR recorded hash; never adopt a locally modified reviewer
    # as managed merely because --with-reviewer was omitted.
    preserved = {key: old_hash for key, old_hash in previous.items()
                 if key.startswith("agents/reviewer.") and key not in desired}
    operations: list[Operation] = []
    conflicts: list[str] = []
    next_entries: dict[str, str] = dict(preserved)
    for key in sorted(preserved):
        safe_path(roots, key)
        operations.append(Operation(key, "preserve", roots.resolve(key), None))
    for key, content in sorted(desired.items()):
        path = safe_path(roots, key)
        new_hash = sha(content)
        next_entries[key] = new_hash
        if not path.exists():
            operations.append(Operation(key, "write", path, content))
            continue
        current_hash = sha_file(path)
        if current_hash == new_hash:
            operations.append(Operation(key, "unchanged", path, None))
            continue
        was_owned_and_clean = key in previous and previous[key] == current_hash
        if was_owned_and_clean:
            operations.append(Operation(key, "write", path, content))
        elif force:
            operations.append(Operation(key, "write", path, content, backup=True))
        else:
            conflicts.append(f"{path} is untracked or locally changed (use --force to back up before replacing)")
    for key, old_hash in sorted(previous.items()):
        if key in desired or key in preserved:
            continue
        path = safe_path(roots, key)
        if not path.exists():
            continue
        clean = sha_file(path) == old_hash
        if clean or force:
            operations.append(Operation(key, "delete", path, None, backup=not clean))
        else:
            conflicts.append(f"{path} is a modified retired file (use --force to back up before removing)")
    verify_safe(roots.manifest, roots.base)
    return operations, conflicts, next_entries


def atomic_write(path: Path, contents: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_path = tempfile.mkstemp(prefix=".review-tools-", dir=str(path.parent))
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(contents)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temp_path, 0o644)
        os.replace(temp_path, path)
    finally:
        if os.path.exists(temp_path):
            os.unlink(temp_path)


def apply_changes(roots: Roots, operations: list[Operation], entries: dict[str, str], *, dry_run: bool, label: str) -> None:
    if dry_run:
        for op in operations:
            print(f"DRY RUN {label}: {op.action.upper():9} {op.path}" + (" (would back up)" if op.backup else ""))
        print(f"DRY RUN {label}: update manifest {roots.manifest}")
        return
    backup_base = roots.base / ".review-tools-backups"
    verify_safe(backup_base, roots.base)
    backup_dir = backup_base / datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    for op in operations:
        if op.backup:
            backup_file = backup_dir / op.key
            verify_safe(backup_file, roots.base)
            backup_file.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(op.path, backup_file)
            print(f"BACKUP {op.path} -> {backup_file}")
        if op.action == "write":
            assert op.content is not None
            atomic_write(op.path, op.content)
            print(f"WRITE {op.path}")
        elif op.action == "delete":
            op.path.unlink()
            print(f"DELETE {op.path}")
    manifest = {"schema_version": SCHEMA_VERSION, "package": "review-tools", "target": roots.target,
                "scope": roots.scope, "entries": entries}
    atomic_write(roots.manifest, (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode("utf-8"))
    print(f"{label}: {len(entries)} installed resources; ownership recorded at {roots.manifest}")


def run(args: argparse.Namespace) -> int:
    selected = TARGETS if args.target == "all" else (args.target,)
    pending = []
    conflicts_all = []
    for target in selected:
        roots = root_paths(target, args.scope, args.project_root, args.home)
        try:
            operations, conflicts, entries = plan_changes(roots, with_reviewer=args.with_reviewer, force=args.force)
        except (ValueError, OSError, json.JSONDecodeError) as exc:
            print(f"ERROR {target}: {exc}", file=sys.stderr)
            return 2
        pending.append((roots, operations, entries))
        conflicts_all.extend(conflicts)
    if conflicts_all:
        for conflict in conflicts_all:
            print(f"CONFLICT {conflict}", file=sys.stderr)
        print("No files changed; use --force only after reviewing the conflicts.", file=sys.stderr)
        return 2
    for roots, operations, entries in pending:
        apply_changes(roots, operations, entries, dry_run=args.dry_run, label=f"{args.action} {roots.target}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    for command in ("install", "upgrade"):
        cmd = sub.add_parser(command, help=f"Safely {command} both review skills and adapters")
        cmd.add_argument("--target", choices=TARGETS + ("all",), required=True)
        cmd.add_argument("--scope", choices=("user", "project"), default="user")
        cmd.add_argument("--project-root", type=Path, help="Project path; default is current working directory")
        cmd.add_argument("--home", type=Path, help="Override HOME only for isolated test/CI installs")
        cmd.add_argument("--with-reviewer", action="store_true", help="Add optional standalone reviewer definition; OMP uses bundled reviewer")
        cmd.add_argument("--force", action="store_true", help="Back up and replace conflicting files without touching unrelated resources")
        cmd.add_argument("--dry-run", action="store_true", help="Report writes without modifying any files")
    args = parser.parse_args()
    return run(args)


if __name__ == "__main__":
    raise SystemExit(main())
