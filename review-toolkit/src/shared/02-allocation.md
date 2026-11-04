## Reviewer allocation — monotonic and risk-aware

Use `F = number of reviewable changed files`, `L = additions + deletions` from the frozen scope. Exclude zero-file scopes. First compute the **domain-reviewer quota** with the nondecreasing envelope of the original policy:

```text
if F == 0: domain = 0
else:
    domain = 1
    if F >= 3 and L >= 100: domain = max(domain, min(2, F))
    if L >= 500:           domain = max(domain, min(4, ceil(F / 3)))
    if L >= 2000:          domain = max(domain, 2, min(8, ceil(F / 2)))
    if L >= 5000:          domain = max(domain, min(16, F))
```

This is monotonic in `F` and `L`. The 2,000-line floor provides **two independent domain passes even for one/two files**; when files are fewer than reviewers, assign two genuinely independent passes over the same critical area and reconcile both. Do not simulate independence by reusing the same response. Reviewer quotas are not confidence claims.

Then classify **verified high-risk** changes. A high-risk signal requires a specific changed code path or contract, not merely a filename, keyword, or speculation. Candidates include:

- Privileged authentication/authorization, secrets, cryptography, unsafe deserialization or untrusted code execution.
- Payments, monetary accounting, irreversible or externally visible financial actions.
- Durable writes, schema/data migrations, deletion, backups or restore, irreversible state transitions.
- Multi-tenant boundaries, identity/ownership scoping, sensitive-data exposure.
- Distributed coordination, concurrency control, idempotency and exactly-once claims.
- Public compatibility, deployment safety and rollback, when actual consumers or release boundaries are identified.

Document the signal as `category + affected path/contract + evidence`. When **at least one** verified signal exists and `F > 0`, add **exactly one targeted independent risk reviewer** in NORMAL, DEEP, and ULTRA. Several risk signals go to that reviewer; do not create one reviewer per keyword. When none is verified, add zero. The risk reviewer is additional to the domain quota, not counted as one of its owners.

In DEEP and ULTRA add **one independent holistic reviewer** in addition to domain and risk reviewers. In NORMAL add none. Thus `requested = domain + risk(0 or 1) + holistic(0 or 1)`. Empty scope requests zero. Task-tool capacity only changes the number of waves (`ceil(requested / capacity)`), never silently reduces the requested independent assignments. Preserve domain ownership in every wave. If task tools or capacity are missing, disclose what was actually completed.

Run the local planner when convenient:

```bash
python3 skillsmd/tools/review_plan.py --files 12 --changed-lines 2050 --depth ULTRA --risk 'durable-data|changed billing write now bypasses transaction' --capacity 2
```

Its `--risk` inputs are claims that **you must first validate against the diff**. The helper checks category and nonempty evidence but cannot prove the claim. It does not launch agents.
