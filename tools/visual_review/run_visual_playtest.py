#!/usr/bin/env python3
"""DATE FACTORY — development-only visual playtest launcher.

Runs res://game/visual_review/visual_playtest_runner.tscn windowed (not headless),
collects PNGs + report.json under _review/visual_playtest/<run_id>/.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parents[1]
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from common.godot_cli import resolve_godot  # noqa: E402

RUNNER_SCENE = "res://game/visual_review/visual_playtest_runner.tscn"

DEFAULT_LAYOUT_RESOLUTIONS = [
    "1280x720",
    "1366x768",
    "1600x900",
    "1920x1080",
    "1920x1200",
    "2560x1440",
    "2560x1080",
    "3440x1440",
    "3840x2160",
]

DEFAULT_GALLERY_RESOLUTIONS = [
    "1280x720",
    "1366x768",
    "1600x900",
    "1920x1080",
    "1920x1200",
    "2560x1440",
    "2560x1080",
    "3440x1440",
    "3840x2160",
]

DEFAULT_PLAYTHROUGH_RESOLUTIONS = [
    "1920x1080",
]

LAYOUT_UI_SCALES_AT_1280 = (100, 125, 150)
GALLERY_UI_SCALES_AT_1280 = (100, 150)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def parse_resolution(text: str) -> tuple[int, int]:
    parts = text.lower().replace(" ", "").split("x")
    if len(parts) != 2:
        raise argparse.ArgumentTypeError(f"invalid resolution: {text}")
    return int(parts[0]), int(parts[1])


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def launch_godot(
    *,
    godot: Path,
    root: Path,
    mode: str,
    run_id: str,
    out_dir: Path,
    width: int,
    height: int,
    ui_scale: int,
    timeout_sec: int,
    log_path: Path,
) -> dict[str, Any]:
    env = os.environ.copy()
    env["DF_VISUAL_MODE"] = mode
    env["DF_VISUAL_RUN_ID"] = run_id
    env["DF_VISUAL_OUT"] = str(out_dir.resolve())
    env["DF_VISUAL_WIDTH"] = str(width)
    env["DF_VISUAL_HEIGHT"] = str(height)
    env["DF_UI_SCALE"] = str(ui_scale)

    cmd = [
        str(godot),
        "--path",
        str(root),
        "--windowed",
        "--resolution",
        f"{width}x{height}",
        RUNNER_SCENE,
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
            timeout=timeout_sec,
            env=env,
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
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text(output, encoding="utf-8")
    return {
        "mode": mode,
        "resolution": f"{width}x{height}",
        "ui_scale": ui_scale,
        "exit_code": exit_code,
        "timed_out": timed_out,
        "elapsed": elapsed,
        "log_path": str(log_path),
        "cmd": cmd,
    }


def collect_pngs(out_dir: Path) -> list[str]:
    paths = sorted(str(p.resolve()) for p in out_dir.rglob("*.png"))
    return paths


def load_partials(out_dir: Path) -> list[dict[str, Any]]:
    partials_dir = out_dir / "partials"
    rows: list[dict[str, Any]] = []
    if not partials_dir.is_dir():
        return rows
    for path in sorted(partials_dir.glob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if isinstance(data, dict):
            rows.append(data)
    return rows


def defect_counts(defects: list[Any]) -> dict[str, int]:
    counts = {"ERROR": 0, "WARNING": 0, "OTHER": 0}
    for defect in defects:
        if isinstance(defect, dict):
            sev = str(defect.get("severity", "OTHER")).upper()
            if sev in counts:
                counts[sev] += 1
            else:
                counts["OTHER"] += 1
        else:
            counts["OTHER"] += 1
    return counts


def merge_reports(
    *,
    mode: str,
    run_id: str,
    out_dir: Path,
    launches: list[dict[str, Any]],
    contact_sheet_note: str,
) -> dict[str, Any]:
    partials = load_partials(out_dir)
    pngs = collect_pngs(out_dir)
    defects: list[Any] = []
    stubs: list[Any] = []
    notes: list[Any] = []
    playthrough: dict[str, Any] = {}
    for partial in partials:
        for d in partial.get("defects", []) or []:
            defects.append(d)
        for s in partial.get("stubs", []) or []:
            stubs.append(s)
        for n in partial.get("notes", []) or []:
            notes.append(n)
        pt = partial.get("playthrough")
        if isinstance(pt, dict) and pt:
            playthrough = pt

    counts = defect_counts(defects)
    report: dict[str, Any] = {
        "mode": mode,
        "run_id": run_id,
        "out_dir": str(out_dir.resolve()),
        "launches": launches,
        "partials": partials,
        "shots": pngs,
        "shot_count": len(pngs),
        "defects": defects,
        "defect_counts": counts,
        "stubs": stubs,
        "notes": notes,
        "playthrough": playthrough,
        "contact_sheets": contact_sheet_note,
    }
    return report


def write_report_md(path: Path, report: dict[str, Any]) -> None:
    counts = report.get("defect_counts") or defect_counts(report.get("defects") or [])
    lines: list[str] = [
        "# Visual Playtest Report",
        "",
        f"- mode: `{report.get('mode')}`",
        f"- run_id: `{report.get('run_id')}`",
        f"- out_dir: `{report.get('out_dir')}`",
        f"- shots: `{report.get('shot_count')}`",
        f"- defects ERROR: `{counts.get('ERROR', 0)}` WARNING: `{counts.get('WARNING', 0)}`",
        f"- contact_sheets: {report.get('contact_sheets')}",
        "",
        "## Launches",
    ]
    for launch in report.get("launches", []):
        lines.append(
            "- `{res}` ui={ui} exit={exit} timed_out={to} ({elapsed:.1f}s) log=`{log}`".format(
                res=launch.get("resolution"),
                ui=launch.get("ui_scale"),
                exit=launch.get("exit_code"),
                to=launch.get("timed_out"),
                elapsed=float(launch.get("elapsed") or 0.0),
                log=launch.get("log_path"),
            )
        )
    lines.append("")
    lines.append("## Defect table")
    defects = report.get("defects") or []
    if not defects:
        lines.append("- (none)")
    else:
        lines.append("| severity | path | message |")
        lines.append("|---|---|---|")
        for defect in defects:
            if isinstance(defect, dict):
                lines.append(
                    "| {sev} | `{path}` | {msg} |".format(
                        sev=defect.get("severity", ""),
                        path=str(defect.get("path", "")).replace("|", "\\|"),
                        msg=str(defect.get("message", "")).replace("|", "\\|"),
                    )
                )
            else:
                lines.append(f"| OTHER |  | {defect} |")
    lines.append("")
    lines.append("## Playthrough")
    pt = report.get("playthrough") or {}
    if not pt:
        lines.append("- (none)")
    else:
        completed = pt.get("completed") or []
        unmet = pt.get("unmet") or []
        lines.append(f"- completed ({len(completed)}): {', '.join(str(x) for x in completed)}")
        lines.append(f"- unmet ({len(unmet)}):")
        if not unmet:
            lines.append("  - (none)")
        else:
            for u in unmet:
                lines.append(f"  - {u}")
    lines.append("")
    lines.append("## Shots")
    shots = report.get("shots") or []
    if not shots:
        lines.append("- (none)")
    else:
        for shot in shots:
            lines.append(f"- `{shot}`")
    lines.append("")
    lines.append("## Stubs / unmet")
    stubs = report.get("stubs") or []
    if not stubs:
        lines.append("- (none)")
    else:
        for stub in stubs:
            lines.append(f"- {stub}")
    lines.append("")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def try_contact_sheets(out_dir: Path, pngs: list[str]) -> str:
    try:
        from PIL import Image  # type: ignore
    except Exception:
        return "skipped (Pillow not available)"

    if not pngs:
        return "skipped (no PNGs)"

    by_res: dict[str, list[Path]] = {}
    for png in pngs:
        path = Path(png)
        # Prefer mode/res nesting: .../<mode>/<WxH>/file.png
        res_name = path.parent.name
        mode_name = path.parent.parent.name if path.parent.parent else ""
        if mode_name in {"layout", "gallery", "playthrough"}:
            res_key = f"{mode_name}_{res_name}"
        else:
            res_key = res_name
        by_res.setdefault(res_key, []).append(path)

    sheets_dir = out_dir / "contact_sheets"
    ensure_dir(sheets_dir)
    made: list[str] = []
    thumb = 240
    cols = 4
    for res_key, paths in sorted(by_res.items()):
        images = []
        for p in sorted(paths):
            try:
                im = Image.open(p)
                im = im.convert("RGB")
                im.thumbnail((thumb, thumb))
                images.append(im)
            except Exception:
                continue
        if not images:
            continue
        rows = (len(images) + cols - 1) // cols
        sheet = Image.new("RGB", (cols * thumb, rows * thumb), (24, 24, 28))
        for idx, im in enumerate(images):
            x = (idx % cols) * thumb
            y = (idx // cols) * thumb
            sheet.paste(im, (x, y))
        out_path = sheets_dir / f"{res_key}.jpg"
        sheet.save(out_path, quality=85)
        made.append(str(out_path))
    if not made:
        return "skipped (failed to build sheets)"
    return "created: " + ", ".join(made)


def build_layout_jobs(resolutions: list[str]) -> list[tuple[str, int, int, int]]:
    jobs: list[tuple[str, int, int, int]] = []
    for res in resolutions:
        w, h = parse_resolution(res)
        if res == "1280x720":
            for scale in LAYOUT_UI_SCALES_AT_1280:
                jobs.append((res, w, h, scale))
        else:
            jobs.append((res, w, h, 100))
    return jobs


def build_gallery_jobs(resolutions: list[str]) -> list[tuple[str, int, int, int]]:
    jobs: list[tuple[str, int, int, int]] = []
    for res in resolutions:
        w, h = parse_resolution(res)
        if res == "1280x720":
            for scale in GALLERY_UI_SCALES_AT_1280:
                jobs.append((res, w, h, scale))
        else:
            jobs.append((res, w, h, 100))
    return jobs


def build_playthrough_jobs(resolutions: list[str]) -> list[tuple[str, int, int, int]]:
    jobs: list[tuple[str, int, int, int]] = []
    for res in resolutions:
        w, h = parse_resolution(res)
        jobs.append((res, w, h, 100))
    return jobs


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="DATE FACTORY visual playtest launcher")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--layout", action="store_true", help="Main menu layout matrix")
    mode.add_argument("--gallery", action="store_true", help="Critical UI gallery")
    mode.add_argument("--playthrough", action="store_true", help="Playthrough driver")
    mode.add_argument("--all", action="store_true", help="layout + gallery + playthrough")
    parser.add_argument("--run-id", required=True, help="Output folder id under _review/visual_playtest/")
    parser.add_argument("--godot", default=None, help="Godot executable path")
    parser.add_argument(
        "--resolutions",
        default=None,
        help="Comma-separated WxH list. Defaults depend on mode "
        "(layout=full matrix, gallery=1280+1920, playthrough=1920+1280).",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=120,
        help="Base per-launch timeout seconds (modes raise floors as needed)",
    )
    return parser.parse_args(argv)


def resolutions_for_mode(mode: str, override: str | None) -> list[str]:
    if override:
        return [r.strip() for r in override.split(",") if r.strip()]
    if mode == "layout":
        return list(DEFAULT_LAYOUT_RESOLUTIONS)
    if mode == "gallery":
        return list(DEFAULT_GALLERY_RESOLUTIONS)
    return list(DEFAULT_PLAYTHROUGH_RESOLUTIONS)


def timeout_for_mode(mode: str, base: int) -> int:
    if mode == "layout":
        return max(90, base)
    if mode == "gallery":
        return max(600, base)
    return max(900, base)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    root = repo_root()
    godot = resolve_godot(args.godot)
    run_id = str(args.run_id).strip()
    if not run_id:
        print("ERROR: --run-id is empty", file=sys.stderr)
        return 2

    out_dir = root / "_review" / "visual_playtest" / run_id
    ensure_dir(out_dir)
    logs_dir = out_dir / "logs"
    ensure_dir(logs_dir)

    modes: list[str] = []
    if args.all:
        modes = ["layout", "gallery", "playthrough"]
    elif args.layout:
        modes = ["layout"]
    elif args.gallery:
        modes = ["gallery"]
    elif args.playthrough:
        modes = ["playthrough"]

    launches: list[dict[str, Any]] = []
    for mode in modes:
        resolutions = resolutions_for_mode(mode, args.resolutions)
        for res in resolutions:
            parse_resolution(res)
        if mode == "layout":
            jobs = build_layout_jobs(resolutions)
        elif mode == "gallery":
            jobs = build_gallery_jobs(resolutions)
        else:
            jobs = build_playthrough_jobs(resolutions)
        timeout = timeout_for_mode(mode, int(args.timeout))

        for res_label, width, height, ui_scale in jobs:
            log_path = logs_dir / f"{mode}_{res_label}_ui{ui_scale}.log"
            print(
                f"[visual_playtest] launching mode={mode} {res_label} ui={ui_scale} timeout={timeout}",
                flush=True,
            )
            result = launch_godot(
                godot=godot,
                root=root,
                mode=mode,
                run_id=run_id,
                out_dir=out_dir,
                width=width,
                height=height,
                ui_scale=ui_scale,
                timeout_sec=timeout,
                log_path=log_path,
            )
            launches.append(result)
            print(
                f"[visual_playtest] done exit={result['exit_code']} "
                f"timed_out={result['timed_out']} elapsed={result['elapsed']:.1f}s log={log_path}",
                flush=True,
            )

    pngs = collect_pngs(out_dir)
    contact_note = try_contact_sheets(out_dir, pngs)
    mode_label = "+".join(modes)
    report = merge_reports(
        mode=mode_label,
        run_id=run_id,
        out_dir=out_dir,
        launches=launches,
        contact_sheet_note=contact_note,
    )
    report_json = out_dir / "report.json"
    report_md = out_dir / "report.md"
    report_json.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    write_report_md(report_md, report)

    print(f"[visual_playtest] shots={len(pngs)} out={out_dir}")
    print(f"[visual_playtest] report={report_json}")
    print(f"[visual_playtest] contact_sheets={contact_note}")
    print(
        f"[visual_playtest] defects ERROR={report['defect_counts']['ERROR']} "
        f"WARNING={report['defect_counts']['WARNING']}",
        flush=True,
    )

    hard_fail = any(
        (launch.get("timed_out") is True) or (launch.get("exit_code") not in (0, None))
        for launch in launches
    )
    if mode_label == "layout" or "layout" in modes:
        layout_pngs = [p for p in pngs if "000_main_menu" in Path(p).name]
        if not layout_pngs:
            print("ERROR: layout produced no 000_main_menu PNGs", file=sys.stderr)
            return 1
    if hard_fail and not pngs:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
