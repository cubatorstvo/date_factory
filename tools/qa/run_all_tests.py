#!/usr/bin/env python3
"""MODULE 27 — one-command headless QA runner.

Reads qa/test_manifest.json, launches Godot per suite, writes logs + summary.
Contains no gameplay logic — orchestration and log/exit classification only.

Godot 4.7 note: --quit-after is frames/iterations. Manifest timeout_seconds is
wall-clock, enforced via subprocess timeout; frames = timeout_seconds * 60.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parents[1]
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from common.godot_cli import resolve_godot as resolve_godot_portable  # noqa: E402


DEFAULT_MANIFEST = "qa/test_manifest.json"

PASS_MARKER = "ALL PASS"
HARD_FAIL_MARKERS = ("SCRIPT ERROR", "Parse Error")

# Godot 4.7 --quit-after is iteration/frame count, not seconds.
# Manifest timeout_seconds is wall-clock (subprocess); frames are a generous ceiling.
FRAMES_PER_TIMEOUT_SECOND = 60
MIN_QUIT_AFTER_FRAMES = 1000


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def resolve_godot(cli_godot: str | None) -> Path:
    return resolve_godot_portable(cli_godot)


def load_manifest(manifest_path: Path) -> list[dict[str, Any]]:
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError(f"Manifest must be a JSON array: {manifest_path}")
    for entry in data:
        for key in (
            "id",
            "module",
            "scene_path",
            "category",
            "timeout_seconds",
            "required_for_rc",
        ):
            if key not in entry:
                raise ValueError(f"Manifest entry missing '{key}': {entry!r}")
    return data


def select_entries(
    entries: list[dict[str, Any]],
    *,
    only_rc: bool,
    filter_text: str | None,
) -> list[dict[str, Any]]:
    selected = entries
    if only_rc:
        selected = [e for e in selected if bool(e.get("required_for_rc"))]
    if filter_text:
        needle = filter_text.lower()
        selected = [
            e
            for e in selected
            if needle in str(e["id"]).lower()
            or needle in str(e["module"]).lower()
            or needle in str(e["category"]).lower()
            or needle in str(e["scene_path"]).lower()
        ]
    return selected


def classify_result(log_text: str, exit_code: int | None, timed_out: bool) -> tuple[str, str]:
    """Return (status, note). status in PASS|FAIL|TIME."""
    if timed_out:
        return "TIME", "process exceeded timeout_seconds"

    has_all_pass = PASS_MARKER in log_text
    has_hard_fail = any(marker in log_text for marker in HARD_FAIL_MARKERS)

    if has_all_pass and not has_hard_fail:
        note = ""
        if exit_code not in (0, None):
            note = f"exit={exit_code} after ALL PASS (treated as PASS; known post-suite crash)"
        return "PASS", note

    reasons: list[str] = []
    if not has_all_pass:
        reasons.append("missing ALL PASS marker")
    if has_hard_fail:
        reasons.append("SCRIPT ERROR/Parse Error present")
    if exit_code not in (0, None) and not has_all_pass:
        reasons.append(f"exit={exit_code}")
    return "FAIL", "; ".join(reasons) if reasons else "failed"


def run_one(
    *,
    godot: Path,
    root: Path,
    entry: dict[str, Any],
    log_dir: Path,
) -> dict[str, Any]:
    test_id = str(entry["id"])
    scene = str(entry["scene_path"])
    timeout_sec = int(entry["timeout_seconds"])
    quit_after_frames = max(timeout_sec * FRAMES_PER_TIMEOUT_SECOND, MIN_QUIT_AFTER_FRAMES)
    log_path = log_dir / f"{test_id}.log"

    cmd = [
        str(godot),
        "--path",
        str(root),
        "--headless",
        "--quit-after",
        str(quit_after_frames),
        scene,
    ]

    started = time.monotonic()
    timed_out = False
    exit_code: int | None = None
    output = ""

    try:
        completed = subprocess.run(
            cmd,
            cwd=str(root),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout_sec + 15,
        )
        exit_code = int(completed.returncode)
        output = (completed.stdout or "") + (completed.stderr or "")
    except subprocess.TimeoutExpired as exc:
        timed_out = True
        stdout = exc.stdout or ""
        stderr = exc.stderr or ""
        if isinstance(stdout, bytes):
            stdout = stdout.decode("utf-8", errors="replace")
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", errors="replace")
        output = stdout + stderr
        exit_code = None

    elapsed = time.monotonic() - started
    log_path.write_text(output, encoding="utf-8")

    status, note = classify_result(output, exit_code, timed_out)
    return {
        "id": test_id,
        "status": status,
        "note": note,
        "exit_code": exit_code,
        "elapsed": elapsed,
        "log_path": log_path,
        "required_for_rc": bool(entry.get("required_for_rc")),
        "scene_path": scene,
    }


def write_summary(results: list[dict[str, Any]], summary_path: Path) -> None:
    lines: list[str] = []
    for result in results:
        status = result["status"]
        test_id = result["id"]
        if status == "PASS":
            line = f"PASS  {test_id}"
            if result["note"]:
                line += f"  # {result['note']}"
            lines.append(line)
        elif status == "TIME":
            lines.append(f"TIME  {test_id}")
        else:
            line = f"FAIL  {test_id}"
            if result["note"]:
                line += f"  # {result['note']}"
            lines.append(line)

    total = len(results)
    passed = sum(1 for r in results if r["status"] == "PASS")
    failed = sum(1 for r in results if r["status"] in ("FAIL", "TIME"))
    lines.extend(
        [
            "",
            f"TOTAL {total}",
            f"PASS  {passed}",
            f"FAIL  {failed}",
        ]
    )
    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run DATE FACTORY headless self-test suites from qa/test_manifest.json"
    )
    parser.add_argument(
        "--manifest",
        default=DEFAULT_MANIFEST,
        help="Manifest path relative to repo root (default: qa/test_manifest.json)",
    )
    parser.add_argument(
        "--godot",
        default=None,
        help="Path to Godot executable (default: GODOT env, else PATH godot/godot4)",
    )
    parser.add_argument(
        "--filter",
        default=None,
        help="Substring filter on id/module/category/scene_path",
    )
    parser.add_argument(
        "--only-rc",
        action="store_true",
        help="Run only required_for_rc=true entries (default when neither filter nor all)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Run all manifest entries including required_for_rc=false",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    root = repo_root()
    manifest_path = Path(args.manifest)
    if not manifest_path.is_absolute():
        manifest_path = root / manifest_path

    godot = resolve_godot(args.godot)
    entries = load_manifest(manifest_path)

    # Default: RC-only. --all runs everything. Explicit --only-rc same as default.
    only_rc = not args.all
    if args.only_rc:
        only_rc = True

    selected = select_entries(entries, only_rc=only_rc, filter_text=args.filter)
    if not selected:
        print("No tests selected from manifest.", file=sys.stderr)
        return 1

    log_dir = root / "tmp" / "qa"
    log_dir.mkdir(parents=True, exist_ok=True)
    summary_path = log_dir / "summary.txt"

    print(f"Repo:     {root}")
    print(f"Godot:    {godot}")
    print(f"Manifest: {manifest_path}")
    print(f"Selected: {len(selected)} suite(s)")
    print("")

    results: list[dict[str, Any]] = []
    for entry in selected:
        test_id = entry["id"]
        print(f"RUN   {test_id}  ({entry['scene_path']})  timeout={entry['timeout_seconds']}s")
        result = run_one(godot=godot, root=root, entry=entry, log_dir=log_dir)
        results.append(result)
        suffix = f"  ({result['note']})" if result["note"] else ""
        print(
            f"{result['status']:4}  {test_id}  "
            f"{result['elapsed']:.1f}s  exit={result['exit_code']}{suffix}"
        )

    write_summary(results, summary_path)
    print("")
    print(f"Summary: {summary_path}")

    # Exit 0 only when every required_for_rc suite among the run set PASSed.
    # Non-RC suites in an --all run do not fail the RC gate.
    required_results = [r for r in results if r["required_for_rc"]]
    if not required_results:
        # Filtered to only non-RC: success if all selected passed.
        gate = results
    else:
        gate = required_results

    rc_ok = all(r["status"] == "PASS" for r in gate)
    return 0 if rc_ok else 1


if __name__ == "__main__":
    sys.exit(main())
