#!/usr/bin/env python3
"""Deterministically check the five static smells in arXiv:2607.01456."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

STATIC_IDS = ("LSB", "LSN", "LSD", "XID", "BP")
XML_TAG = re.compile(
    r"<\s*/?\s*[A-Za-z][\w:.-]*(?:\s+[^<>]*?)?\s*/?\s*>"
)
PATH_BACKSLASH = re.compile(
    r"(?:\b[A-Za-z]:\\|\\\\[\w.$-]+\\[\w.$-]+|(?<!\\)\b[\w.-]+\\[\w.-]+)"
)


def _unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1].replace("''", "'")
    if len(value) >= 2 and value[0] == value[-1] == '"':
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value[1:-1]
    return value


def _frontmatter_value(lines: list[str], key: str) -> str:
    match_key = re.compile(rf"^{re.escape(key)}\s*:\s*(.*)$")
    top_level_key = re.compile(r"^[A-Za-z0-9_-]+\s*:")
    for index, line in enumerate(lines):
        match = match_key.match(line)
        if not match:
            continue
        value = match.group(1).strip()
        if value in {"|", "|-", "|+", ">", ">-", ">+"}:
            block: list[str] = []
            for continuation in lines[index + 1 :]:
                if top_level_key.match(continuation):
                    break
                block.append(continuation.strip())
            separator = "\n" if value.startswith("|") else " "
            return separator.join(part for part in block if part)
        return _unquote(value)
    return ""


def parse_skill(text: str) -> tuple[str, str, str, list[str]]:
    lines = text.lstrip("\ufeff").splitlines()
    warnings: list[str] = []
    if not lines or lines[0].strip() != "---":
        return "", "", text, ["No opening YAML frontmatter delimiter."]

    try:
        end = next(
            index
            for index, line in enumerate(lines[1:], 1)
            if line.strip() == "---"
        )
    except StopIteration:
        return "", "", text, ["No closing YAML frontmatter delimiter."]

    frontmatter = lines[1:end]
    name = _frontmatter_value(frontmatter, "name")
    description = _frontmatter_value(frontmatter, "description")
    if not name:
        warnings.append("Could not parse frontmatter name.")
    if not description:
        warnings.append("Could not parse frontmatter description.")
    return name, description, "\n".join(lines[end + 1 :]), warnings


def check(path: Path) -> dict[str, object]:
    text = path.read_text(encoding="utf-8")
    name, description, body, warnings = parse_skill(text)
    body_words = len(body.split())
    metrics = {
        "body_words": body_words,
        "name_characters": len(name),
        "description_characters": len(description),
    }
    findings: list[dict[str, object]] = []

    def add(smell_id: str, name_: str, evidence: str) -> None:
        findings.append({"id": smell_id, "name": name_, "evidence": evidence})

    if body_words > 5000:
        add("LSB", "Lengthy Skill Body", f"{body_words} body words > 5000")
    if name and len(name) > 64:
        add("LSN", "Lengthy Skill Name", f"{len(name)} characters > 64")
    if description and len(description) > 1024:
        add(
            "LSD",
            "Lengthy Skill Description",
            f"{len(description)} characters > 1024",
        )
    xml = XML_TAG.search(description)
    if xml:
        add("XID", "XML Included Description", f"tag-shaped text: {xml.group(0)!r}")
    backslash = PATH_BACKSLASH.search(text)
    if backslash:
        line = text.count("\n", 0, backslash.start()) + 1
        add("BP", "Backslash Path", f"line {line}: {backslash.group(0)!r}")

    return {
        "path": str(path),
        "paper": "arXiv:2607.01456v2",
        "checked": list(STATIC_IDS),
        "metrics": metrics,
        "findings": findings,
        "warnings": warnings,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Check LSB, LSN, LSD, XID, and BP. Frontmatter parsing supports "
            "top-level name/description scalars and |/> block scalars. BP "
            "matches path-shaped backslashes to avoid flagging every escape."
        )
    )
    parser.add_argument("skill_md", type=Path)
    parser.add_argument("--pretty", action="store_true", help="indent JSON output")
    parser.add_argument(
        "--strict", action="store_true", help="exit 1 when a smell is present"
    )
    args = parser.parse_args()

    if not args.skill_md.is_file():
        parser.error(f"not a file: {args.skill_md}")
    result = check(args.skill_md)
    print(json.dumps(result, indent=2 if args.pretty else None, ensure_ascii=False))
    return int(bool(args.strict and result["findings"]))


if __name__ == "__main__":
    raise SystemExit(main())
