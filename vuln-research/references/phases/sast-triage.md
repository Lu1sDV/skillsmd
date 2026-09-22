# SAST False Positive Calibration — Phase L4.5

Load this file before triaging any SAST tool output during Phase L4.5 (Static Analysis False Positive Calibration). It contains per-severity FP-rate priors, the common false-positive pattern checklist, and the 5-step calibration workflow.

---

SAST tools generate noise. Calibrate expectations before triaging. The rates below are **field-experience estimates, not published measurements** — they vary by tool, language, and rule pack. Treat them as priors to be replaced by your own per-rule FP rate once you have ≥10 triaged samples in the target codebase.

| Severity | Typical False Positive Rate | Action |
|----------|---------------------------|--------|
| **P0/P1** (Critical/High) | 30–50% | Triage every finding manually — high FP rate but high impact when real |
| **P2** (Medium) | 50–70% | Batch triage, prioritize sinks with direct user input |
| **P3** (Low) | 70–90% | Skim for patterns, don't chase individual findings |

**Common false positive patterns:**
- **Dead code sinks**: Function exists but is never called from a reachable route
- **Framework-sanitized paths**: SAST flags `innerHTML` but React's JSX auto-escapes; flags `query()` but ORM parameterizes
- **Test file hits**: SAST scanning test fixtures, mock data, or example payloads
- **Vendor/third-party code**: Flagging sinks in `node_modules/`, `vendor/`, or vendored dependencies
- **Constant inputs**: Sink reached only with hardcoded/constant values, not user input

**Calibration workflow:**
1. Run SAST, sort by severity descending
2. For P0/P1: manually verify each — trace source to sink, confirm controllability
3. For P2/P3: sample 10 findings, measure FP rate, extrapolate to decide effort allocation
4. Suppress confirmed false positives with inline comments or tool-specific ignore rules
5. Track FP rate per rule — disable rules consistently above 90% FP in your stack
