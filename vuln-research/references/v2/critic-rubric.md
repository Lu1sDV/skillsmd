# REPORT Critic Rubric

> Loaded by the REPORT phase critic agent (spec §7, R2). Defines the three checks, the severity ladder, and a worked-example table the critic uses to calibrate verdicts. CRITICAL blocks the report; WARNING is recorded structurally in `critic_findings` and surfaces in the final write-up without halting it.

---

## 1. The Three Critic Checks

For every `gr_findings` row with `confirmation_status = 'confirmed'`, the critic runs each check independently and emits at most one `critic_findings` row per `(finding_id, check_kind)`. Absent row = check passed.

| Check | Question the critic must answer | What "fail" looks like |
|---|---|---|
| **comprehension** | Does the finding's prose statement actually match the cited evidence (lines, functions, payloads)? | Wrong sink function, wrong taint path, contradicts evidence, cites a sanitized path as if unsanitized, mislabels bug class. |
| **eligibility** | Does this finding meet the project's disclosure/bounty criteria — i.e., is it NOT an intended feature, NOT a "by-design" privileged operation, NOT documented behavior under the observed role/preconditions? | Sink is documented admin behavior under admin role; precondition strictness gates exceed the user-supplied threshold; intended_feature_classification.is_documented_behavior = true AND role gate passes. |
| **attack_scenario** | Is there a plausible end-to-end attacker trigger? Source must be externally reachable; sink consequence must be weaponizable; chain must compose under realistic preconditions. | No externally reachable entry point; trigger requires already-authenticated admin; "RCE" that needs filesystem write the attacker has no path to; SSRF without a reachable network namespace. |

---

## 2. Severity Ladder

| Severity | Meaning | Effect on report |
|---|---|---|
| **WARNING** | Check failed in a way that weakens the finding but does not invalidate it. Reviewer should see the caveat. | Stored in `critic_findings`; surfaced under the finding's "Critic Notes" section. Report still ships. |
| **CRITICAL** | Check failed in a way that the finding cannot stand: wrong evidence, intended feature under observed role, no attacker trigger. | Stored in `critic_findings`; **blocks the final report** until the finding is fixed, downgraded to Observations, or re-confirmed. |

A finding may accrue multiple critic_findings rows (one per check_kind). Any single CRITICAL row blocks the report.

---

## 3. Worked Examples (17)

Each row maps a realistic finding shape to a verdict. The critic uses these as anchors when classifying its own verdicts.

| # | Finding shape | check_kind | Verdict | Why |
|---|---|---|---|---|
| 1 | "SQLi via `getUser($id)`"; evidence cites `PDO::prepare($sql); $stmt->execute([$id])` — i.e., a parameterized path. | comprehension | **CRITICAL** | Evidence contradicts the claim; the cited path is parameterized, no taint reaches a string-concatenated query. Finding cannot stand. |
| 2 | XSS via `echo $title` in admin-only template; intended_feature_classification: documented = true, observed_role_at_sink = admin, precondition_strictness = admin_only. | eligibility | **WARNING** | Admin self-XSS is documented under admin role; not in scope per most bounty programs. Recorded but not blocking — some programs do accept it. |
| 3 | SSRF via webhook URL field; sink is `curl_exec`, but the deployment manifest pins the container to a network without metadata-server reach and without internal services. | attack_scenario | **CRITICAL** | No externally weaponizable consequence: the SSRF cannot reach anything sensitive in the deployed topology. |
| 4 | RCE via Pickle deserialization on `/upload`; source = uploaded file body; sink = `pickle.loads`. Evidence + trace match. | comprehension | (pass — no row) | Statement matches evidence; bug class correct. |
| 5 | RCE via Pickle deserialization on `/upload`; route requires authenticated admin; classification: admin_only, role = admin, documented = false. | eligibility | **WARNING** | Authenticated admin RCE is still a finding under most programs, but precondition strictness lowers severity. Recorded. |
| 6 | Path traversal in `/static/<path>`; evidence shows `os.path.join(BASE, path)` with no `..` filter; trace closes; static handler is unauthenticated. | attack_scenario | (pass — no row) | Reachable, weaponizable, no preconditions beyond network access. |
| 7 | "Command injection in `archive($name)`"; evidence cites `subprocess.run([cmd, name], shell=False)` — argv form, no shell interpretation. | comprehension | **CRITICAL** | Argv invocation does not interpret metachars; bug class label is wrong. |
| 8 | LDAP injection in `findUser(uid)`; sink reached unauthenticated; evidence and trace match; impact = auth bypass via filter-rewriting. | attack_scenario | (pass — no row) | Closed chain with external trigger. |
| 9 | Open redirect via `?next=`; documented behavior (login flow returns to `next`); observed role = anonymous; precondition_strictness = trivial; not on allowlist. | eligibility | **WARNING** | Documented but exploitable as phishing primitive; many programs treat as Low. Recorded so reviewer knows the doc context. |
| 10 | "SSTI in `/preview`"; evidence shows Jinja2 render of a template **file path**, not user-controlled template **content**; user input only selects which template to render from a fixed directory. | comprehension | **CRITICAL** | SSTI requires user-controlled template body; this is at most LFI/path-traversal-on-templates. Wrong class. |
| 11 | Deserialization gadget chain in Java `readObject`; sink reached via authenticated webhook; chain proven; impact = RCE. | attack_scenario | (pass — no row) | Chain closes end-to-end with a real trigger. |
| 12 | "IDOR on `/orders/<id>`" — evidence: handler does `Order.find(id).where(user_id: current_user.id)`. | comprehension | **CRITICAL** | The `where(user_id: current_user.id)` clause IS the auth check; finding misreads the query. |
| 13 | XXE in `/import-xml`; observed_role = user (authenticated, no special permission); documented = false; libxml entity loader enabled by config. | eligibility | (pass — no row) | Not intended behavior; user-role precondition is acceptable; documented = false. |
| 14 | "Race condition in payment processing"; described as TOCTOU between balance check and debit; PoC depends on attacker controlling thread scheduling on a single-tenant deployment. | attack_scenario | **WARNING** | Real race, but exploit requires uncommon scheduling control; reviewer should know the realism caveat. Not CRITICAL — the bug exists, the attacker just needs concurrency luck. |
| 15 | Mass assignment in user-profile update; observed_role = user; field exposed = `is_admin`; no allowlist filter; documented = false. | eligibility | (pass — no row) | Classic privilege escalation; eligible. |
| 16 | "Stored XSS in comments"; preview component sanitizes via DOMPurify on render; evidence shows sanitizer is mandatory in every component that displays comments. | attack_scenario | **WARNING** | Stored payload exists, but render-side sanitizer blocks weaponization in all observed contexts. Worth recording — sanitizer could be bypassed or new render paths added — but not blocking. |
| 17 | "Auth bypass via JWT `none` alg"; evidence shows server config `enforce_alg = 'RS256'` and rejects `alg=none` tokens in the verifier path. | comprehension | **CRITICAL** | Cited code rejects the attack; statement contradicts evidence. |

---

## 4. Procedure

For each confirmed finding:

1. Read the finding's `gr_findings` row + cited evidence + `intended_feature_classification` for the sink.
2. For each of the three `check_kind` values: emit a `critic_findings` row only on failure. Pick severity using §2 + the §3 anchors.
3. The orchestrator (single writer per spec §3) flushes critic rows at the end of Phase 5.
4. If any CRITICAL row exists, the report is blocked and the finding is routed back to Phase 4 (re-prove) or demoted to Observations, depending on which check failed.

> Doctrine reminder: WARNING is for "reviewer needs the caveat"; CRITICAL is for "this finding does not stand as written." Do not soften CRITICAL to keep a finding alive.
