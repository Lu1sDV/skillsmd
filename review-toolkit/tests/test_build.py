import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from tools.build_skills import generated_skills, write_or_check


class BuildTest(unittest.TestCase):
    def test_generated_matches_source(self):
        self.assertTrue(write_or_check(check=True))

    def test_shared_policy_identical_in_both_skills(self):
        files = generated_skills()
        a = files["skills/review-code/SKILL.md"].decode()
        b = files["skills/review-pr/SKILL.md"].decode()
        for p in sorted((ROOT / "src/shared").glob("*.md")):
            content = p.read_text().rstrip()
            self.assertIn(content, a, p.name)
            self.assertIn(content, b, p.name)

    def test_source_edit_changes_both_generated_skills(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_root = Path(tmp)
            shutil.copytree(ROOT / "src", tmp_root / "src")
            old = generated_skills(tmp_root)
            policy = tmp_root / "src/shared/03-gate-report.md"
            policy.write_text(policy.read_text() + "\nNEW POLICY TEST MARKER\n")
            new = generated_skills(tmp_root)
            for name in old:
                self.assertNotEqual(old[name], new[name]); self.assertIn(b"NEW POLICY TEST MARKER", new[name])

    def test_broken_marker_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            temp = Path(tmp)
            shutil.copytree(ROOT / "src", temp / "src")
            (temp / "src/review-code.md").write_text("---\nname: review-code\n---\n{{shared:missing}}")
            with self.assertRaises(ValueError):
                generated_skills(temp)
