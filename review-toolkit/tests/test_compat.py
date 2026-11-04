import json
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from tools.check_harnesses import check_one, load_pins, parse_version


class HarnessPinTest(unittest.TestCase):
    def test_pins_are_explicit_exact_versions(self):
        pins = load_pins()
        self.assertEqual(set(pins["harnesses"]), {"pi", "omp", "codex", "claude-code"})
        for item in pins["harnesses"].values():
            self.assertRegex(item["version"], r"^\d+\.\d+\.\d+$")
            self.assertNotIn("latest", item["package"])

    def test_parse_cli_version(self):
        self.assertEqual(parse_version("codex-cli 0.166.0"), "0.166.0")
        self.assertEqual(parse_version("claude v2.1.311\n"), "2.1.311")
        self.assertIsNone(parse_version("no version given"))

    @patch("tools.check_harnesses.shutil.which", return_value="/usr/bin/pi")
    @patch("tools.check_harnesses.subprocess.run")
    def test_matched(self, run, _which):
        run.return_value = subprocess.CompletedProcess([], 0, stdout="pi 0.85.1", stderr="")
        spec = load_pins()["harnesses"]["pi"]
        self.assertEqual(check_one("pi", spec)["status"], "match")

    @patch("tools.check_harnesses.shutil.which", return_value="/usr/bin/pi")
    @patch("tools.check_harnesses.subprocess.run")
    def test_mismatched(self, run, _which):
        run.return_value = subprocess.CompletedProcess([], 0, stdout="pi 0.99.0", stderr="")
        spec = load_pins()["harnesses"]["pi"]
        self.assertEqual(check_one("pi", spec)["status"], "mismatch")

    @patch("tools.check_harnesses.shutil.which", return_value=None)
    def test_missing(self, _which):
        spec = load_pins()["harnesses"]["pi"]
        self.assertEqual(check_one("pi", spec)["status"], "missing")

    def test_ci_matrix_from_pins(self):
        output = subprocess.check_output([sys.executable, str(ROOT / "tools/check_harnesses.py"), "--ci-matrix"], text=True)
        actual = json.loads(output)["include"]
        self.assertEqual({x["target"]: x["version"] for x in actual},
                         {k: v["version"] for k, v in load_pins()["harnesses"].items()})
