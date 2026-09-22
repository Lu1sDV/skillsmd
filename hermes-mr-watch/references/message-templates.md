# Message Templates

12 alternative per-MR line formats for the watcher stdout. All are plain text,
deterministic, one line per MR, and use only fields available in the single
anonymous GitLab MR request the script already makes.

## Implemented dense templates

`scripts/watch_gitlab_mr_findings.py` implements four selectable renderers:

| `WATCHER_TEMPLATE` | Purpose |
|---|---|
| `combined` (default) | Security + CVSS + Readiness + Timeline; merged first with exact merge time and SHA |
| `rich` | Title, CVSS, severity, pipeline, mergeability, diff size, notes, milestone, age, analysis tag |
| `audit` | Structured timestamps, CVSS, and key/value fields for evidence review |
| `alert` | Minimal heartbeat with CVSS; merged state dominates with full `merged_at` and short commit SHA |

Every renderer pins merged MRs first. A merged line never substitutes poll time
for merge time: it reads GitLab's `merged_at` and `merge_commit_sha`.

## Contract variables

| Variable | Meaning | Example |
|---|---|---|
| `iid` | merge request IID | `246660` |
| `state_display` | `merged` / `unmerged` / `check failed` | `unmerged` |
| `ts` | UTC timestamp | `2026-08-18T17:13:38Z` |
| `analysis` | `LIVE-CONFIRMED` / `SECURITY-FINDINGS` | |
| `url` | GitLab MR link | |
| `emoji_ok` | status glyph | ✅/❌ |
| `title` | MR title (truncate to ~60 chars) | |
| `author` | author username | `Andyschoenen` |
| `milestone` | milestone title or `-` | `19.4` |
| `severity_label` | from labels, e.g. `S3`, or empty | |
| `pipeline_icon` | 🟢 success 🔴 failed ⚪ none | |
| `notes_count` | discussion count | `104` |
| `diff_size` | changed lines | `126` |
| `merge_status_short` | ≤12-char detailed_merge_status | `draft` |
| `age_days` | days since created_at | `41` |
| `conf_pct` | local finding confidence % or empty | `90` |

## Templates

1. **Emoji Status Prefix** — eye filters failures without reading:
   `{emoji_ok} !{iid} {state_display} {ts} [{analysis}]\n{url}`
2. **Compact Dashboard** — pipeline + mergeability + confidence in one glance:
   `{pipeline_icon}{emoji_ok} !{iid} {merge_status_short} | {analysis} {conf_pct}% | {severity_label} | {state_display}\n{url}`
3. **Severity First** — security triage sorting up front:
   `[{severity_label or '-'}]{emoji_ok} !{iid} {state_display} — {analysis} {conf_pct}%\n{url}`
4. **Title Context** — 32 unchanged lines become distinguishable:
   `{emoji_ok} !{iid} ({state_display}, {age_days}d) {title[:60]} — {analysis}\n{url}`
5. **Age Sorted Signal** — staleness pops visually:
   `{emoji_ok} {age_days:>3}d !{iid} {state_display} {merge_status_short} [{analysis}]\n{url}`
6. **Author Accountability** — fast follow-up pinging:
   `{emoji_ok} !{iid} @{author} {state_display} {ts}\n{url}`
7. **Review Load View** — shows review burden the current format hides:
   `{emoji_ok} !{iid} +{diff_size} 💬{notes_count} {pipeline_icon} {merge_status_short} {state_display}\n{url}`
8. **Milestone Tracking** — release-focused watching:
   `{emoji_ok} !{iid} [{milestone}] {state_display} — {analysis}\n{url}`
9. **Confidence Ranked** — ignore low-confidence noise at a glance:
   `{emoji_ok} !{iid} {analysis} {conf_pct}% | {severity_label} | {state_display}\n{url}`
10. **Minimal Delta** — shortest deterministic line; drops timestamp noise:
    `{emoji_ok} !{iid} {state_display} {merge_status_short} — {url}`
11. **Fixed-Width Columns** — vertical alignment in monospace clients:
    `{emoji_ok} !{iid:<7} {state_display:<8} {merge_status_short:<11} {pipeline_icon} {analysis}\n{url}`
12. **Full Audit Trail** — everything for log mining (longest):
    `{emoji_ok} !{iid} {state_display} {ts} | {analysis}{f' {conf_pct}%' if conf_pct else ''} {severity_label} | {pipeline_icon}{merge_status_short} | +{diff_size} 💬{notes_count} | @{author} [{milestone}] {age_days}d\n{url}`

## Hard limits

- Telegram cap is 4096 chars/message. Current 32-line output is already
  ~5100 chars → Hermes chunking splits it into 2 messages per tick. Template 12
  (~250 chars/line) would make it 4+ fragments. Templates 1, 9, 10 keep it at 2.
- Empty `severity_label`/`conf_pct`/`milestone`: guard with `or '-'` or
  conditional join, or lines get double spaces.
- Truncate `title`; some MR titles exceed 100 chars.
- Keep `\n` before `url` so links render tappable.

## Enabling a template

Edit `status_message()` in `scripts/watch_gitlab_mr_findings.py` to use the
chosen format string, extend `fetch_live()` to keep the extra fields, update
the state schema only if you persist new fields, then run the standard deploy
gates (self-test → backup → scp → hash check → built-in tick).
