#!/usr/bin/env python3
"""Combined lifecycle and security watcher for GitLab finding MRs.

Four selectable output templates (``WATCHER_TEMPLATE`` = combined | rich |
audit | alert, default combined). All keep independent per-MR fetches,
persist-before-stdout, nonblocking locking, malformed-state fail-closed, and
exit 0 on expected per-MR errors. Merged MRs sort first with the exact GitLab
``merged_at`` and merge SHA.
"""
from __future__ import annotations

import fcntl
import io
import json
import os
import sys
import tempfile
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable, TextIO

# One source of truth: adding an IID requires its analysis class and every
# frozen CVSS v3.1 base score. Empty scores mean "not scored", never zero.
# Sources: reports/new-2026-08-21/cvss-rescore-2026-08-19.json,
# reports/gitlab/{246660,246760,249142}, reports/new-2026-08-21/{246517,250584},
# and reports/all-findings-2026-08-{22,24}.json.
MR_CONFIG = {
    "246660": {"analysis": "LIVE-CONFIRMED", "cvss": (6.5,)},
    "246760": {"analysis": "LIVE-CONFIRMED", "cvss": (7.5,)},
    "212828": {"analysis": "SECURITY-FINDINGS", "cvss": ()},
    "213613": {"analysis": "SECURITY-FINDINGS", "cvss": (4.3,)},
    "217637": {"analysis": "SECURITY-FINDINGS", "cvss": ()},
    "218413": {"analysis": "SECURITY-FINDINGS", "cvss": ()},
    "219090": {"analysis": "LIVE-CONFIRMED", "cvss": (6.0,)},
    "223204": {"analysis": "SECURITY-FINDINGS", "cvss": (7.0,)},
    "222865": {"analysis": "SECURITY-FINDINGS", "cvss": (6.5,)},
    "231558": {"analysis": "SECURITY-FINDINGS", "cvss": ()},
    "234471": {"analysis": "SECURITY-FINDINGS", "cvss": ()},
    "234618": {"analysis": "LIVE-CONFIRMED", "cvss": (7.5,)},
    "234619": {"analysis": "SECURITY-FINDINGS", "cvss": (7.4,)},
    "225453": {"analysis": "SECURITY-FINDINGS", "cvss": (4.3,)},
    "238980": {"analysis": "SECURITY-FINDINGS", "cvss": ()},
    "238556": {"analysis": "SECURITY-FINDINGS", "cvss": (6.5,)},
    "238617": {"analysis": "SECURITY-FINDINGS", "cvss": (4.3,)},
    "239617": {"analysis": "SECURITY-FINDINGS", "cvss": ()},
    "242408": {"analysis": "LIVE-CONFIRMED", "cvss": ()},
    "242562": {"analysis": "SECURITY-FINDINGS", "cvss": (7.4,)},
    "242698": {"analysis": "LIVE-CONFIRMED", "cvss": (6.8, 4.7)},
    "243149": {"analysis": "SECURITY-FINDINGS", "cvss": ()},
    "245428": {"analysis": "SECURITY-FINDINGS", "cvss": (6.1,)},
    "245438": {"analysis": "SECURITY-FINDINGS", "cvss": (6.0,)},
    "245441": {"analysis": "SECURITY-FINDINGS", "cvss": (6.0,)},
    "245563": {"analysis": "SECURITY-FINDINGS", "cvss": ()},
    "246517": {"analysis": "SECURITY-FINDINGS", "cvss": (3.8,)},
    "246522": {"analysis": "SECURITY-FINDINGS", "cvss": (4.3,)},
    "246577": {"analysis": "LIVE-CONFIRMED", "cvss": ()},
    "247170": {"analysis": "SECURITY-FINDINGS", "cvss": (7.5,)},
    "247669": {"analysis": "SECURITY-FINDINGS", "cvss": (3.5,)},
    "247401": {"analysis": "LIVE-CONFIRMED", "cvss": (8.1,)},
    "247822": {"analysis": "LIVE-CONFIRMED", "cvss": ()},
    "247978": {"analysis": "SECURITY-FINDINGS", "cvss": (7.5,)},
    "248208": {"analysis": "LIVE-CONFIRMED", "cvss": (7.4, 6.8, 6.1)},
    "249009": {"analysis": "SECURITY-FINDINGS", "cvss": (3.5,)},
    "249142": {"analysis": "LIVE-CONFIRMED", "cvss": (6.3,)},
    "249111": {"analysis": "SECURITY-FINDINGS", "cvss": (8.8,)},
    "249197": {"analysis": "LIVE-CONFIRMED", "cvss": ()},
    "249687": {"analysis": "SECURITY-FINDINGS", "cvss": ()},
    # The frozen HIGH finding is not numerically scored; the older 4.9 score
    # covers only its LOW sibling, so reporting 4.9 as the MR maximum is false.
    "250249": {"analysis": "LIVE-CONFIRMED", "cvss": ()},
    "250584": {"analysis": "LIVE-CONFIRMED", "cvss": (7.1,)},
    "245055": {"analysis": "SECURITY-FINDINGS", "cvss": (6.5,)},
    "245437": {"analysis": "SECURITY-FINDINGS", "cvss": (6.5,)},
    "245487": {"analysis": "SECURITY-FINDINGS", "cvss": (6.5,)},
    "245585": {"analysis": "SECURITY-FINDINGS", "cvss": (8.8,)},
    "246439": {"analysis": "SECURITY-FINDINGS", "cvss": (4.1, 3.7)},
    "246788": {"analysis": "SECURITY-FINDINGS", "cvss": (5.3, 5.3)},
    "249242": {"analysis": "SECURITY-FINDINGS", "cvss": (8.8,)},
    "249301": {"analysis": "SECURITY-FINDINGS", "cvss": (4.3,)},
    "249626": {"analysis": "SECURITY-FINDINGS", "cvss": (4.3,)},
    "250941": {"analysis": "SECURITY-FINDINGS", "cvss": (5.3,)},
    "251137": {"analysis": "SECURITY-FINDINGS", "cvss": (6.3, 4.3)},
    "251138": {"analysis": "SECURITY-FINDINGS", "cvss": (4.3,)},
    "251143": {"analysis": "SECURITY-FINDINGS", "cvss": (6.3,)},
    "251202": {"analysis": "SECURITY-FINDINGS", "cvss": (8.8, 8.8)},
    "203203": {"analysis": "SECURITY-FINDINGS", "cvss": (4.2,)},
    "207393": {"analysis": "SECURITY-FINDINGS", "cvss": (7.1, 5.9)},
    "215928": {"analysis": "SECURITY-FINDINGS", "cvss": (4.3,)},
    "246711": {"analysis": "SECURITY-FINDINGS", "cvss": (4.3,)},
    "247181": {"analysis": "SECURITY-FINDINGS", "cvss": (6.5,)},
    "249145": {"analysis": "SECURITY-FINDINGS", "cvss": (4.9,)},
    "249553": {"analysis": "SECURITY-FINDINGS", "cvss": (4.3,)},
    "250607": {"analysis": "SECURITY-FINDINGS", "cvss": (6.5,)},
    "251369": {"analysis": "SECURITY-FINDINGS", "cvss": (5.7,)},
    "251157": {"analysis": "SECURITY-FINDINGS", "cvss": (4.9,)},
    "251552": {"analysis": "SECURITY-FINDINGS", "cvss": (7.3,)},
    "251884": {"analysis": "SECURITY-FINDINGS", "cvss": (6.5, 6.5)},
    "251942": {"analysis": "SECURITY-FINDINGS", "cvss": (5.3,)},
}
IIDS = tuple(MR_CONFIG)
API_ROOT = "https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab/merge_requests"
MR_ROOT = "https://gitlab.com/gitlab-org/gitlab/-/merge_requests"
SCHEMA_VERSION = 2
STATE_NAME = ".gitlab-mr-findings-watch-v1.json"
LOCK_NAME = ".gitlab-mr-findings-watch-v1.lock"
VALID_STATES = frozenset(("opened", "merged", "closed"))
TEMPLATE_NAMES = ("combined", "rich", "audit", "alert")


def default_state() -> dict:
    return {"schema_version": SCHEMA_VERSION, "mrs": {}}


def normalize_state(value: object) -> dict:
    if not isinstance(value, dict) or value.get("schema_version") not in (1, SCHEMA_VERSION):
        raise ValueError("invalid watcher state schema")
    raw_mrs = value.get("mrs")
    if not isinstance(raw_mrs, dict):
        raise ValueError("invalid watcher state mrs")
    normalized = default_state()
    for iid, item in raw_mrs.items():
        if iid not in IIDS or not isinstance(item, dict):
            raise ValueError("invalid watcher state entry")
        lifecycle = item.get("last_good_state")
        if lifecycle not in VALID_STATES:
            raise ValueError("invalid watcher lifecycle state")
        entry: dict = {"last_good_state": lifecycle}
        if item.get("merged_at") is not None:
            entry["merged_at"] = str(item["merged_at"])
        if item.get("merge_sha") is not None:
            entry["merge_sha"] = str(item["merge_sha"])
        normalized["mrs"][iid] = entry
    return normalized


def read_state(path: Path) -> dict:
    if not path.exists():
        return default_state()
    return normalize_state(json.loads(path.read_text(encoding="utf-8")))


def write_state(path: Path, value: dict) -> None:
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(value, handle, sort_keys=True, separators=(",", ":"))
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
        directory_fd = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    except BaseException:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass
        raise


def fetch_live(iid: str) -> dict:
    request = urllib.request.Request(
        f"{API_ROOT}/{iid}", headers={"User-Agent": "hermes-mr-findings-watch/1"}
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        payload = json.load(response)
    if (
        not isinstance(payload, dict)
        or payload.get("state") not in VALID_STATES
    ):
        raise ValueError("missing or invalid lifecycle state")
    return {
        "state": payload["state"],
        "title": str(payload.get("title") or "")[:60],
        "author": str((payload.get("author") or {}).get("username") or "?"),
        "milestone": str((payload.get("milestone") or {}).get("title") or "-"),
        "sev": next(
            (
                label.split("::", 1)[1]
                for label in payload.get("labels") or []
                if isinstance(label, str) and label.startswith("severity::")
            ),
            "",
        ),
        "pipe_icon": {"success": "🟢", "failed": "🔴"}.get(
            (payload.get("pipeline") or {}).get("status"), "⚪"
        ),
        "ms_short": str(payload.get("detailed_merge_status") or "")[:12],
        "diff": int(payload.get("changes_count") or 0),
        "notes": int(payload.get("user_notes_count") or 0),
        "created_at": str(payload.get("created_at") or ""),
        "merged_at": payload.get("merged_at"),
        "merge_sha": payload.get("merge_commit_sha"),
        "draft": bool(payload.get("draft")),
        "labels": tuple(str(label) for label in payload.get("labels") or []),
        "updated_at": str(payload.get("updated_at") or ""),
        "closed_at": payload.get("closed_at"),
        "source_branch": str(payload.get("source_branch") or "-"),
        "target_branch": str(payload.get("target_branch") or "-"),
    }


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def iso_z(value: datetime) -> str:
    return value.isoformat(timespec="seconds").replace("+00:00", "Z")


def compact_hm(iso_text: str) -> str:
    try:
        parsed = datetime.fromisoformat(iso_text.replace("Z", "+00:00"))
    except ValueError:
        return "?"
    return parsed.astimezone(timezone.utc).strftime("%m-%d %H:%M")


def analysis_status(iid: str) -> str:
    return str(MR_CONFIG[iid]["analysis"])


def cvss_rating(score: float) -> str:
    if score >= 9.0:
        return "Critical"
    if score >= 7.0:
        return "High"
    if score >= 4.0:
        return "Medium"
    return "Low"


def cvss_summary(iid: str) -> str:
    scores = tuple(float(score) for score in MR_CONFIG[iid]["cvss"])
    if not scores:
        return "not scored"
    maximum = max(scores)
    if len(scores) == 1:
        return f"{maximum:.1f} {cvss_rating(maximum)}"
    listed = "/".join(f"{score:.1f}" for score in scores)
    return (
        f"{maximum:.1f} {cvss_rating(maximum)} max; "
        f"{len(scores)} findings: {listed}"
    )


STATUS_RANK = {"merged": 0, "check failed": 1, "unmerged": 2}
TAG_RANK = {"LIVE-CONFIRMED": 0, "SECURITY-FINDINGS": 1}


def sort_key(entry: tuple[str, str, dict]) -> tuple[int, int, int]:
    iid, status, detail = entry
    if status == "merged":
        state_rank = 0
    elif detail.get("state") == "closed":
        state_rank = 1
    elif status == "unmerged":
        state_rank = 2
    else:
        state_rank = 3
    return (state_rank, TAG_RANK.get(analysis_status(iid), 1), int(iid))


def age_days(created_at: str, now_value: datetime) -> int:
    try:
        created = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
    except ValueError:
        return -1
    return max(0, (now_value - created).days)


# Template line builders. Each returns ONE line without trailing newline.

def last_good_suffix(detail: dict) -> str:
    if detail.get("last_good_state") == "merged":
        sha = str(detail.get("merge_sha") or "")[:8]
        return f" — last good: MERGED {detail.get('merged_at') or '?'} [{sha}]"
    return f" — last good: {detail.get('last_good_state') or 'unknown'}"


def _line_rich(index: int, iid: str, status: str, detail: dict, now_value: datetime) -> str:
    icon = "❌" if status == "merged" else ("⚠️" if status == "check failed" else "·")
    if status == "merged":
        return (
            f"{index}. 🚨 MERGED !{iid} at "
            f"{iso_z(datetime.fromisoformat(str(detail['merged_at']).replace('Z', '+00:00'))) if detail.get('merged_at') else '?'} "
            f"[{str(detail.get('merge_sha') or '')[:8]}] {analysis_status(iid)} "
            f"CVSS {cvss_summary(iid)}\n   {MR_ROOT}/{iid}"
        )
    if status == "check failed":
        return (
            f"{index}. {icon} !{iid} check failed at {iso_z(now_value)}"
            f"{last_good_suffix(detail)} — {analysis_status(iid)} "
            f"CVSS {cvss_summary(iid)}\n   {MR_ROOT}/{iid}"
        )
    sev = f" S{detail['sev']}" if detail.get("sev") else ""
    pipe = detail.get("pipe_icon", "⚪")
    ms = detail.get("ms_short", "")
    notes = detail.get("notes", 0)
    diff = detail.get("diff", 0)
    milestone = detail.get("milestone", "-")
    title60 = detail.get("title", "")
    age = age_days(detail.get("created_at", ""), now_value)
    return (
        f"{index}. · !{iid} unmerged {pipe}{sev} [{ms}] +{diff} 💬{notes} "
        f"{milestone} {age}d “{title60}” {analysis_status(iid)} "
        f"CVSS {cvss_summary(iid)}\n   {MR_ROOT}/{iid}"
    )


def _line_audit(index: int, iid: str, status: str, detail: dict, now_value: datetime) -> str:
    stamp = iso_z(now_value)
    tag = analysis_status(iid)
    if status == "merged":
        return (
            f"{index}. MERGED !{iid} merged_at={detail.get('merged_at') or '?'} "
            f"sha={str(detail.get('merge_sha') or '')[:8]} {tag} "
            f"cvss={cvss_summary(iid)}\n   {MR_ROOT}/{iid}"
        )
    if status == "check failed":
        return (
            f"{index}. FAIL !{iid} at={stamp}{last_good_suffix(detail)} {tag} "
            f"cvss={cvss_summary(iid)}\n   {MR_ROOT}/{iid}"
        )
    created_hm = compact_hm(detail.get("created_at", ""))
    updated_note = ""
    return (
        f"{index}. OPEN !{iid} at={stamp} created={created_hm} "
        f"+{detail.get('diff', 0)} 💬{detail.get('notes', 0)} "
        f"{detail.get('pipe_icon', '⚪')}{detail.get('ms_short', '')} "
        f"[{detail.get('milestone', '-')}] {tag} "
        f"cvss={cvss_summary(iid)}\n   {MR_ROOT}/{iid}"
    )


def _line_alert(index: int, iid: str, status: str, detail: dict, now_value: datetime) -> str:
    if status == "merged":
        when = str(detail.get("merged_at") or "?")
        sha = str(detail.get("merge_sha") or "")[:8]
        return (
            f"{index}. 🚨 !{iid} MERGED ⏰ {when} commit:{sha} "
            f"{analysis_status(iid)} CVSS {cvss_summary(iid)}\n   {MR_ROOT}/{iid}"
        )
    if status == "check failed":
        return (
            f"{index}. ⚠️ !{iid} CHECK FAILED{last_good_suffix(detail)} "
            f"{analysis_status(iid)} CVSS {cvss_summary(iid)}\n"
            f"   {MR_ROOT}/{iid}"
        )
    return (
        f"{index}. ⏳ !{iid} still open ({detail.get('ms_short', '')}, "
        f"{detail.get('pipe_icon', '⚪')}) {analysis_status(iid)} "
        f"CVSS {cvss_summary(iid)}\n   {MR_ROOT}/{iid}"
    )


def _line_combined(index: int, iid: str, status: str, detail: dict, now_value: datetime) -> str:
    severity = f"S{detail['sev']}" if detail.get("sev") else "-"
    updated = compact_hm(detail.get("updated_at", ""))
    facts = (
        f"{analysis_status(iid)} | CVSS: {cvss_summary(iid)} | {severity} | "
        f"{detail.get('pipe_icon', '⚪')} merge:{detail.get('ms_short') or '-'} "
        f"draft:{'Y' if detail.get('draft') else 'N'} "
        f"Δ{detail.get('diff', 0)} 💬{detail.get('notes', 0)} upd:{updated}"
    )
    if status == "merged":
        return (
            f"{index}. 🚨 !{iid} MERGED — WHEN {detail.get('merged_at') or '?'} "
            f"— SHA {str(detail.get('merge_sha') or '')[:12]}\n"
            f"{detail.get('title') or '-'} | {facts}\n{MR_ROOT}/{iid}"
        )
    if status == "check failed":
        return (
            f"{index}. ⚠️ !{iid} CHECK FAILED{last_good_suffix(detail)} | "
            f"{analysis_status(iid)} | CVSS: {cvss_summary(iid)}\n{MR_ROOT}/{iid}"
        )
    if detail.get("state") == "closed":
        return (
            f"{index}. ⛔ !{iid} CLOSED/unmerged — WHEN "
            f"{detail.get('closed_at') or '?'} | {facts}\n{MR_ROOT}/{iid}"
        )
    return f"{index}. ⏳ !{iid} OPEN/unmerged | {facts}\n{MR_ROOT}/{iid}"


TEMPLATE_BUILDERS = {
    "combined": _line_combined,
    "rich": _line_rich,
    "audit": _line_audit,
    "alert": _line_alert,
}


def active_template() -> str:
    name = os.environ.get("WATCHER_TEMPLATE", "combined")
    return name if name in TEMPLATE_BUILDERS else "combined"


def status_message(observations: list[tuple[str, str, dict]], observed_at: datetime) -> str:
    ordered = sorted(observations, key=sort_key)
    builder = TEMPLATE_BUILDERS[active_template()]
    lines: list[str] = []
    for index, (iid, status, detail) in enumerate(ordered, 1):
        lines.append(builder(index, iid, status, detail, observed_at))
    header = ""
    merged = [entry for entry in ordered if entry[1] == "merged"]
    if merged:
        header = f"🔔 {len(merged)} MR(S) MERGED THIS RUN:\n"
    return header + "\n".join(lines)


def run_once(
    data_dir: Path,
    fetch: Callable[[str], dict],
    stdout: TextIO,
    stderr: TextIO,
    now: Callable[[], datetime] = utc_now,
) -> int:
    data_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    state_path = data_dir / STATE_NAME
    lock_path = data_dir / LOCK_NAME
    with lock_path.open("a+", encoding="utf-8") as lock:
        os.chmod(lock_path, 0o600)
        try:
            fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return 0
        try:
            state = read_state(state_path)
        except (OSError, ValueError, json.JSONDecodeError) as error:
            print(f"watcher state unavailable: {error}", file=stderr)
            return 2
        next_state = {"schema_version": SCHEMA_VERSION, "mrs": {}}
        observations: list[tuple[str, str, dict]] = []
        for iid in IIDS:
            previous = state["mrs"].get(iid, {})
            try:
                current_detail = fetch(iid)
                current = current_detail["state"]
                if current not in VALID_STATES:
                    raise ValueError("missing or invalid lifecycle state")
            except Exception as error:
                print(f"watch failed for !{iid}: {error}", file=stderr)
                entry = {
                    "last_good_state": previous.get("last_good_state", "opened"),
                    "merged_at": previous.get("merged_at"),
                    "merge_sha": previous.get("merge_sha"),
                }
                next_state["mrs"][iid] = entry
                observations.append((iid, "check failed", dict(entry)))
                continue
            record: dict = {"last_good_state": current}
            if current == "merged":
                record["merged_at"] = current_detail.get("merged_at")
                record["merge_sha"] = current_detail.get("merge_sha")
            next_state["mrs"][iid] = record
            display = "merged" if current == "merged" else "unmerged"
            observations.append((iid, display, dict(current_detail)))
        if next_state != state:
            write_state(state_path, next_state)
        print(status_message(observations, now()), file=stdout)
        return 0


def fixture_fetch(values: dict[str, object]) -> Callable[[str], dict]:
    def fetch(iid: str) -> dict:
        value = values[iid]
        if isinstance(value, Exception):
            raise value
        if isinstance(value, dict):
            return dict(value)
        return {"state": str(value)}

    return fetch


def self_test() -> int:
    import shutil

    root = Path(tempfile.mkdtemp(prefix="hermes-mr-dense-test-"))
    fixed_now = datetime(2026, 8, 20, 12, 0, 0, tzinfo=timezone.utc)
    first, second = IIDS[0], IIDS[1]
    try:

        def call(values: dict[str, object]) -> tuple[int, str, str]:
            out, err = io.StringIO(), io.StringIO()
            code = run_once(root, fixture_fetch(values), out, err, lambda: fixed_now)
            return code, out.getvalue(), err.getvalue()

        opened = {iid: {"state": "opened"} for iid in IIDS}
        assert tuple(MR_CONFIG) == IIDS
        assert cvss_summary("246660") == "6.5 Medium"
        assert cvss_summary("242698") == "6.8 Medium max; 2 findings: 6.8/4.7"
        assert cvss_summary("250249") == "not scored"
        assert cvss_summary("249009") == "3.5 Low"
        # Bootstrap all-open: every line shows unmerged with URL.
        code, out, err = call(opened)
        assert code == 0 and err == ""
        assert "!246660" in out and "unmerged" in out
        assert "CVSS: 6.5 Medium" in out and "CVSS: not scored" in out
        assert MR_ROOT in out
        # Repeat unchanged: same statuses.
        code2, out2, _ = call(opened)
        assert code2 == 0 and "unmerged" in out2
        # One merge: merged line pins top with merged_at + sha; header appears.
        merged_payload = {
            "state": "merged",
            "merged_at": "2026-08-20T11:55:00.123456+00:00",
            "merge_sha": "95fb932a03ac570be167f632f9a932e4ffcd9fd5",
        }
        code3, out3, _ = call({**opened, first: merged_payload})
        assert code3 == 0
        assert "MERGED" in out3 and "2026-08-20T11:55:00.123456+00:00" in out3
        assert "95fb932a" in out3
        assert out3.index("!246660") < out3.index(f"!{second}")
        # Persisted state carries merged metadata.
        stored = read_state(root / STATE_NAME)["mrs"][first]
        assert stored["last_good_state"] == "merged"
        assert stored["merged_at"] == "2026-08-20T11:55:00.123456+00:00"
        assert stored["merge_sha"] == "95fb932a03ac570be167f632f9a932e4ffcd9fd5"
        # Failure after merge keeps last-good merged view, exit 0.
        failing = {iid: RuntimeError("fixture down") for iid in IIDS}
        code4, out4, err4 = call(failing)
        assert code4 == 0
        assert "MERGED" in out4 and "watch failed for" in err4
        # Reopen resets to unmerged and drops merge metadata.
        code5, out5, _ = call(opened)
        assert code5 == 0 and "🚨 MERGED" not in out5 and "unmerged" in out5
        stored_after = read_state(root / STATE_NAME)["mrs"][first]
        assert stored_after["last_good_state"] == "opened"
        assert "merged_at" not in stored_after
        # Malformed state fails closed preserving bytes.
        malformed = b"not-json\n"
        (root / STATE_NAME).write_bytes(malformed)
        code6, out6, err6 = call(opened)
        assert code6 == 2 and out6 == "" and "state unavailable" in err6
        assert (root / STATE_NAME).read_bytes() == malformed
        (root / STATE_NAME).unlink()
        call(opened)  # recreate valid state
        # Lock contention silent.
        import fcntl as _fcntl

        with (root / LOCK_NAME).open("a+", encoding="utf-8") as held:
            _fcntl.flock(held.fileno(), _fcntl.LOCK_EX | _fcntl.LOCK_NB)
            before_lock = (root / STATE_NAME).read_bytes()
            code7, out7, _ = call(opened)
            assert code7 == 0 and out7 == ""
            assert (root / STATE_NAME).read_bytes() == before_lock
            _fcntl.flock(held.fileno(), _fcntl.LOCK_UN)
        # Template selection via env.
        os.environ["WATCHER_TEMPLATE"] = "alert"
        try:
            code8, out8, _ = call(opened)
            assert code8 == 0 and "⏳" in out8
            code9, out9, _ = call({**opened, second: merged_payload})
            assert code9 == 0 and "🚨" in out9 and "MERGED" in out9
        finally:
            os.environ.pop("WATCHER_TEMPLATE", None)
        # Audit template shows structured key=value fields.
        os.environ["WATCHER_TEMPLATE"] = "audit"
        try:
            code10, out10, _ = call(opened)
            assert code10 == 0 and "OPEN !" in out10
        finally:
            os.environ.pop("WATCHER_TEMPLATE", None)
        print("fixture tests: passed")
        return 0
    finally:
        shutil.rmtree(root)


def main(argv: list[str]) -> int:
    if argv == ["--self-test"]:
        return self_test()
    if argv:
        print("usage: watch_gitlab_mr_findings.py [--self-test]", file=sys.stderr)
        return 2
    data_dir = Path(os.environ.get("HERMES_DATA_DIR", "/opt/data"))
    return run_once(data_dir, fetch_live, sys.stdout, sys.stderr)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
