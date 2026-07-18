#!/usr/bin/env python3
"""Runnable black-box checks for check_static_smells.py."""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

CHECKER = Path(__file__).with_name("check_static_smells.py")


def run_checker(contents: str, *args: str) -> tuple[subprocess.CompletedProcess[str], dict]:
    with tempfile.TemporaryDirectory() as directory:
        target = Path(directory) / "SKILL.md"
        target.write_text(contents, encoding="utf-8")
        result = subprocess.run(
            ["python", str(CHECKER), str(target), *args],
            check=False,
            capture_output=True,
            text=True,
        )
        return result, json.loads(result.stdout)


class StaticSmellCheckerTest(unittest.TestCase):
    def test_clean_skill(self) -> None:
        result, report = run_checker(
            "---\nname: useful-skill\n"
            "description: Audits useful files when quality checks are requested.\n"
            "---\n\n# Useful Skill\n\nUse `scripts/check.py`.\n"
        )
        self.assertEqual(result.returncode, 0)
        self.assertEqual(report["findings"], [])
        self.assertEqual(report["checked"], ["LSB", "LSN", "LSD", "XID", "BP"])

    def test_all_five_smells_and_strict_exit(self) -> None:
        contents = (
            "---\n"
            f"name: {'n' * 65}\n"
            "description: >\n"
            f"  <unsafe>{'d' * 1025}</unsafe>\n"
            "---\n"
            "Use scripts\\check.py.\n"
            + ("word " * 5001)
        )
        result, report = run_checker(contents, "--strict")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(
            {finding["id"] for finding in report["findings"]},
            {"LSB", "LSN", "LSD", "XID", "BP"},
        )

    def test_non_tag_comparison_and_regex_escape_are_clean(self) -> None:
        _, report = run_checker(
            "---\nname: compare\n"
            "description: Checks whether x < y when comparison help is requested.\n"
            "---\n\nUse the regex `\\d+`.\n"
        )
        self.assertEqual(report["findings"], [])


if __name__ == "__main__":
    unittest.main()
