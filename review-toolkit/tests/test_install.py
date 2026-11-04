import contextlib
import io
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import install
from tools.build_skills import generated_skills


class InstallerTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.project = self.work / "repo"
        self.project.mkdir()
        self.home = self.work / "home"
        self.home.mkdir()

    def args(self, target, action="install", *, scope="project", dry_run=False,
             with_reviewer=True, force=False):
        return type("Args", (), {"target": target, "action": action, "scope": scope,
                                 "project_root": self.project, "home": self.home,
                                 "with_reviewer": with_reviewer, "force": force,
                                 "dry_run": dry_run})()

    def invoke(self, args):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return install.run(args)

    def test_dry_run_no_writes(self):
        self.assertEqual(self.invoke(self.args("all", dry_run=True)), 0)
        self.assertEqual(list(self.project.iterdir()), [])

    def test_install_and_upgrade_all_project(self):
        self.assertEqual(self.invoke(self.args("all")), 0)
        for target in install.TARGETS:
            roots = install.root_paths(target, "project", self.project, self.home)
            self.assertTrue(roots.manifest.is_file())
            for key, content in install.layout_for(target, True, "project").items():
                self.assertEqual(roots.resolve(key).read_bytes(), content)
            self.assertEqual(self.invoke(self.args(target, action="upgrade")), 0)

    def test_install_and_upgrade_all_user(self):
        self.assertEqual(self.invoke(self.args("all", scope="user")), 0)
        for target in install.TARGETS:
            roots = install.root_paths(target, "user", self.project, self.home)
            for key in install.layout_for(target, True, "user"):
                self.assertTrue(roots.resolve(key).is_file(), key)
            self.assertEqual(self.invoke(self.args(target, "upgrade", scope="user")), 0)

    def test_codex_project_has_no_legacy_prompts(self):
        self.assertEqual(self.invoke(self.args("codex")), 0)
        roots = install.root_paths("codex", "project", self.project, self.home)
        self.assertFalse((roots.base / "prompts").exists())
        self.assertTrue((roots.skill_base / "skills/review-pr/SKILL.md").is_file())

    def test_omp_does_not_override_bundled_reviewer(self):
        self.assertEqual(self.invoke(self.args("omp")), 0)
        self.assertFalse((self.project / ".omp/agents/reviewer.md").exists())

    def test_modified_owned_file_blocks_upgrade_without_force(self):
        self.assertEqual(self.invoke(self.args("pi")), 0)
        roots = install.root_paths("pi", "project", self.project, self.home)
        path = roots.resolve("skills/review-code/SKILL.md")
        path.write_text("my local custom instructions")
        self.assertEqual(self.invoke(self.args("pi", "upgrade")), 2)
        self.assertEqual(path.read_text(), "my local custom instructions")

    def test_force_backs_up_local_modifications(self):
        self.assertEqual(self.invoke(self.args("pi")), 0)
        roots = install.root_paths("pi", "project", self.project, self.home)
        path = roots.resolve("skills/review-code/SKILL.md")
        path.write_text("my changed instructions")
        self.assertEqual(self.invoke(self.args("pi", "upgrade", force=True)), 0)
        backups = list((roots.base / ".review-tools-backups").glob("*/skills/review-code/SKILL.md"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "my changed instructions")
        self.assertEqual(path.read_bytes(), generated_skills()["skills/review-code/SKILL.md"])

    def test_unowned_existing_file_blocks_install(self):
        roots = install.root_paths("pi", "project", self.project, self.home)
        path = roots.resolve("prompts/review-code.md")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("preexisting unrelated command")
        self.assertEqual(self.invoke(self.args("pi")), 2)
        self.assertFalse(roots.manifest.exists())
        self.assertEqual(path.read_text(), "preexisting unrelated command")

    def test_unowned_same_content_is_adopted(self):
        roots = install.root_paths("pi", "project", self.project, self.home)
        path = roots.resolve("prompts/review-code.md")
        path.parent.mkdir(parents=True, exist_ok=True)
        content = install.layout_for("pi", True, "project")["prompts/review-code.md"]
        path.write_bytes(content)
        self.assertEqual(self.invoke(self.args("pi")), 0)
        self.assertEqual(path.read_bytes(), content)

    def test_reviewer_preserved_without_flag(self):
        self.assertEqual(self.invoke(self.args("pi")), 0)
        roots = install.root_paths("pi", "project", self.project, self.home)
        reviewer = roots.resolve("agents/reviewer.md")
        reviewer.write_text("local changed reviewer")
        old_hash = install.read_manifest(roots)["agents/reviewer.md"]
        self.assertEqual(self.invoke(self.args("pi", "upgrade", with_reviewer=False)), 0)
        self.assertEqual(reviewer.read_text(), "local changed reviewer")
        self.assertEqual(install.read_manifest(roots)["agents/reviewer.md"], old_hash)
        self.assertEqual(self.invoke(self.args("pi", "upgrade", with_reviewer=True)), 2)

    def test_symlinked_target_rejected_even_with_force(self):
        outside = self.work / "outside.txt"
        outside.write_text("sensitive file")
        roots = install.root_paths("pi", "project", self.project, self.home)
        path = roots.resolve("prompts/review-code.md")
        path.parent.mkdir(parents=True)
        path.symlink_to(outside)
        self.assertEqual(self.invoke(self.args("pi", force=True)), 2)
        self.assertEqual(outside.read_text(), "sensitive file")

    def test_unrelated_file_is_left_alone(self):
        outside = self.project / ".omp/commands/my-private-command.md"
        outside.parent.mkdir(parents=True)
        outside.write_text("private")
        self.assertEqual(self.invoke(self.args("omp")), 0)
        self.assertEqual(outside.read_text(), "private")

    def test_malicious_manifest_path_rejected(self):
        roots = install.root_paths("pi", "project", self.project, self.home)
        roots.base.mkdir(parents=True)
        roots.manifest.write_text(json.dumps({"schema_version": 2, "target": "pi", "scope": "project",
                                              "entries": {"../../elsewhere": "a" * 64}}))
        self.assertEqual(self.invoke(self.args("pi", force=True)), 2)

    def test_all_target_conflict_preflight_is_atomic(self):
        unowned = self.project / ".claude/skills/review-pr/SKILL.md"
        unowned.parent.mkdir(parents=True)
        unowned.write_text("cannot overwrite")
        self.assertEqual(self.invoke(self.args("all")), 2)
        self.assertFalse((self.project / ".pi").exists())
        self.assertFalse((self.project / ".omp").exists())
        self.assertFalse((self.project / ".codex").exists())

    def test_src_edited_install_uses_compiled_policy_not_stale_generated_file(self):
        # Contract: layout uses generated_skills(ROOT) directly, not a cached dist file.
        original = (ROOT / "src/shared/03-gate-report.md").read_text()
        try:
            (ROOT / "src/shared/03-gate-report.md").write_text(original + "\nCANONICAL-SENTINEL\n")
            self.assertIn(b"CANONICAL-SENTINEL", install.layout_for("pi")["skills/review-code/SKILL.md"])
        finally:
            (ROOT / "src/shared/03-gate-report.md").write_text(original)
