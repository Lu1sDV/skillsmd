#!/usr/bin/env python3
"""Silent lifecycle watcher for a fixed pair of public GitLab merge requests."""
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

IIDS = ("246660", "246760")
API_ROOT = "https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab/merge_requests"
MR_ROOT = "https://gitlab.com/gitlab-org/gitlab/-/merge_requests"
ANALYSIS_STATUS = "LIVE-CONFIRMED"
SCHEMA_VERSION = 1
STATE_NAME = ".gitlab-mr-lifecycle-watch-v1.json"
LOCK_NAME = ".gitlab-mr-lifecycle-watch-v1.lock"
VALID_STATES = frozenset(("opened", "merged", "closed"))


def default_state() -> dict:
    return {"schema_version": SCHEMA_VERSION, "mrs": {}}


def normalize_state(value: object) -> dict:
    if not isinstance(value, dict) or value.get("schema_version") != SCHEMA_VERSION:
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
        normalized["mrs"][iid] = {"last_good_state": lifecycle}
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


def fetch_live(iid: str) -> str:
    request = urllib.request.Request(
        f"{API_ROOT}/{iid}", headers={"User-Agent": "hermes-mr-lifecycle-watch/1"}
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        payload = json.load(response)
    if not isinstance(payload, dict) or payload.get("state") not in VALID_STATES:
        raise ValueError("missing or invalid lifecycle state")
    return payload["state"]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def status_message(observations: list[tuple[str, str]], observed_at: str) -> str:
    return "\n".join(
        f"{index}. MR !{iid} status: {status} "
        f"at {observed_at} — analysis: {ANALYSIS_STATUS} — {MR_ROOT}/{iid}"
        for index, (iid, status) in enumerate(observations, 1)
    )


def run_once(
    data_dir: Path,
    fetch: Callable[[str], str],
    stdout: TextIO,
    stderr: TextIO,
    now: Callable[[], str] = utc_now,
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
        next_state = {"schema_version": SCHEMA_VERSION, "mrs": dict(state["mrs"])}
        observations: list[tuple[str, str]] = []
        for iid in IIDS:
            try:
                current = fetch(iid)
                if current not in VALID_STATES:
                    raise ValueError("missing or invalid lifecycle state")
            except Exception as error:
                print(f"watch failed for !{iid}: {error}", file=stderr)
                observations.append((iid, "check failed"))
                continue
            next_state["mrs"][iid] = {"last_good_state": current}
            observations.append((iid, "merged" if current == "merged" else "unmerged"))
        if next_state != state:
            write_state(state_path, next_state)
        print(status_message(observations, now()), file=stdout)
        return 0


def fixture_fetch(values: dict[str, object]) -> Callable[[str], str]:
    def fetch(iid: str) -> str:
        value = values[iid]
        if isinstance(value, Exception):
            raise value
        return str(value)
    return fetch


def self_test() -> int:
    import shutil
    root = Path(tempfile.mkdtemp(prefix="hermes-mr-watch-test-"))
    observed_at = "2026-08-17T09:30:00Z"
    try:
        def call(
            values: dict[str, object],
            directory: Path = root,
            out: io.StringIO | None = None,
        ):
            out, err = out or io.StringIO(), io.StringIO()
            code = run_once(directory, fixture_fetch(values), out, err, lambda: observed_at)
            return code, out.getvalue(), err.getvalue()

        def expected(status_660: str, status_760: str) -> str:
            return (
                f"1. MR !246660 status: {status_660} at {observed_at} — "
                f"analysis: LIVE-CONFIRMED — {MR_ROOT}/246660\n"
                f"2. MR !246760 status: {status_760} at {observed_at} — "
                f"analysis: LIVE-CONFIRMED — {MR_ROOT}/246760\n"
            )

        opened = {iid: "opened" for iid in IIDS}
        display = {"opened": "unmerged", "merged": "merged", "closed": "unmerged"}
        for lifecycle in VALID_STATES:
            first_seen = {iid: lifecycle for iid in IIDS}
            assert call(first_seen, root / f"bootstrap-{lifecycle}") == (
                0,
                expected(display[lifecycle], display[lifecycle]),
                "",
            )
        assert call(opened) == (0, expected("unmerged", "unmerged"), "")
        state_path = root / STATE_NAME
        initial = state_path.read_bytes()
        assert call(opened) == (0, expected("unmerged", "unmerged"), "")
        assert state_path.read_bytes() == initial
        code, out, err = call({"246660": "merged", "246760": "opened"})
        assert (code, out, err) == (0, expected("merged", "unmerged"), "")
        assert call({"246660": "merged", "246760": "closed"}) == (
            0,
            expected("merged", "unmerged"),
            "",
        )
        assert call(opened) == (0, expected("unmerged", "unmerged"), "")
        assert call({"246660": "opened", "246760": "closed"}) == (
            0,
            expected("unmerged", "unmerged"),
            "",
        )
        before_failure = state_path.read_bytes()
        for failure in (
            RuntimeError("404 fixture"), RuntimeError("429 fixture"),
            TimeoutError("fixture timeout"), ValueError("invalid JSON fixture"),
            ValueError("missing state fixture"), ValueError("unknown state fixture"),
        ):
            code, out, err = call({"246660": failure, "246760": "closed"})
            assert code == 0 and out == expected("check failed", "unmerged")
            assert "!246660" in err and state_path.read_bytes() == before_failure
        partial = root / "partial-failure"
        assert call(opened, partial) == (0, expected("unmerged", "unmerged"), "")
        code, out, err = call(
            {"246660": RuntimeError("fixture failure"), "246760": "closed"},
            partial,
        )
        assert (code, out) == (0, expected("check failed", "unmerged"))
        assert "!246660" in err
        partial_state = read_state(partial / STATE_NAME)["mrs"]
        assert partial_state == {
            "246660": {"last_good_state": "opened"},
            "246760": {"last_good_state": "closed"},
        }
        malformed = b"not-json\n"
        state_path.write_bytes(malformed)
        code, out, err = call(opened)
        assert code == 2 and out == "" and "state unavailable" in err and state_path.read_bytes() == malformed
        state_path.unlink()
        assert call(opened) == (0, expected("unmerged", "unmerged"), "")
        with (root / LOCK_NAME).open("a+", encoding="utf-8") as held:
            fcntl.flock(held.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            before_lock = state_path.read_bytes()
            assert call({"246660": "merged", "246760": "closed"}) == (0, "", "")
            assert state_path.read_bytes() == before_lock
        observed: list[bytes] = []
        class PersistProbe(io.StringIO):
            def __init__(self, fail: bool = False) -> None:
                super().__init__()
                self.fail = fail

            def write(self, text: str) -> int:
                observed.append(state_path.read_bytes())
                if self.fail:
                    raise OSError("fixture output failure")
                return super().write(text)
        probe = PersistProbe()
        assert run_once(
            root,
            fixture_fetch({"246660": "merged", "246760": "opened"}),
            probe,
            io.StringIO(),
            lambda: observed_at,
        ) == 0
        assert observed and b'"last_good_state":"merged"' in observed[0]
        assert call(opened) == (0, expected("unmerged", "unmerged"), "")
        try:
            run_once(
                root,
                fixture_fetch({"246660": "merged", "246760": "opened"}),
                PersistProbe(fail=True),
                io.StringIO(),
                lambda: observed_at,
            )
        except OSError as error:
            assert str(error) == "fixture output failure"
        else:
            raise AssertionError("output failure did not propagate")
        assert b'"last_good_state":"merged"' in state_path.read_bytes()
        assert (state_path.stat().st_mode & 0o777) == 0o600
        assert ((root / LOCK_NAME).stat().st_mode & 0o777) == 0o600
        print("fixture tests: 14 passed")
        return 0
    finally:
        shutil.rmtree(root)


def main(argv: list[str]) -> int:
    if argv == ["--self-test"]:
        return self_test()
    if argv:
        print("usage: watch_gitlab_mrs.py [--self-test]", file=sys.stderr)
        return 2
    data_dir = Path(os.environ.get("HERMES_DATA_DIR", "/opt/data"))
    return run_once(data_dir, fetch_live, sys.stdout, sys.stderr)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
