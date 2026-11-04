import json
import math
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from tools.review_plan import RiskSignal, build_plan, domain_reviewers, parse_risk


class AllocationTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(domain_reviewers(0, 9999999), 0)
        self.assertEqual(build_plan(0, 10000, "ULTRA")["total_requested"], 0)

    def test_edges(self):
        expected = [(2, 499, 1), (3, 99, 1), (3, 100, 2), (3, 499, 2),
                    (3, 500, 2), (3, 1999, 2), (3, 2000, 2), (3, 4999, 2),
                    (3, 5000, 3), (1, 2000, 2), (2, 10000, 2), (12, 500, 4),
                    (12, 2000, 6), (12, 5000, 12), (20, 5000, 16)]
        for f, l, value in expected:
            with self.subTest(f=f, l=l):
                self.assertEqual(domain_reviewers(f, l), value)

    def test_monotonic_in_lines(self):
        lines = [0, 99, 100, 101, 499, 500, 501, 1999, 2000, 2001, 4999, 5000, 5001, 100000]
        for files in range(1, 51):
            counts = [domain_reviewers(files, l) for l in lines]
            self.assertEqual(counts, sorted(counts), (files, counts))

    def test_monotonic_in_files(self):
        for lines in (0, 99, 100, 499, 500, 1999, 2000, 4999, 5000, 999999):
            counts = [domain_reviewers(f, lines) for f in range(0, 101)]
            self.assertEqual(counts, sorted(counts), (lines, counts))

    def test_risk_add_one_per_change_not_signal(self):
        r1 = RiskSignal("payments", "billing/charge.py: debit changed")
        r2 = RiskSignal("schema-migration", "migrations/042.sql table dropped")
        base = build_plan(2, 50)
        risky = build_plan(2, 50, risks=[r1, r2])
        self.assertEqual(risky["targeted_risk_reviewers"], 1)
        self.assertEqual(risky["total_requested"], base["total_requested"] + 1)

    def test_depth_adds_one_holistic(self):
        normal = build_plan(12, 2100, "NORMAL")
        deep = build_plan(12, 2100, "DEEP")
        ultra = build_plan(12, 2100, "ULTRA")
        self.assertEqual(deep["total_requested"], normal["total_requested"] + 1)
        self.assertEqual(ultra["total_requested"], deep["total_requested"])

    def test_capacity_does_not_reduce_quota(self):
        p = build_plan(12, 2100, "ULTRA", risks=[RiskSignal("payments", "money/ledger transfer changed")], capacity=2)
        self.assertEqual(p["total_requested"], 8)
        self.assertEqual(p["waves"], math.ceil(8 / 2))

    def test_risk_validation(self):
        with self.assertRaises(ValueError):
            RiskSignal("payments", "vague")
        with self.assertRaises(ValueError):
            parse_risk("payments")
        with self.assertRaises(ValueError):
            parse_risk("security|auth code changed")
        self.assertEqual(parse_risk("payments|money/charge.py changed").category, "payments")

    def test_invalid_dimensions(self):
        for files, lines in ((-1, 1), (1, -1)):
            with self.assertRaises(ValueError):
                domain_reviewers(files, lines)
        with self.assertRaises(ValueError):
            build_plan(1, 10, capacity=0)

    def test_cli_json(self):
        out = subprocess.check_output([sys.executable, str(ROOT / "tools/review_plan.py"),
                    "--files", "3", "--changed-lines", "500", "--depth", "deep"], text=True)
        self.assertEqual(json.loads(out)["domain_reviewers"], 2)
