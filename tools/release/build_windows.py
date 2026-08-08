#!/usr/bin/env python3
"""DATE FACTORY MODULE 28 — Windows release builder.

Developer:
  py -3 tools/release/build_windows.py

Release gate:
  py -3 tools/release/build_windows.py --release

Optional Steam AppID seam (does not invent defaults):
  py -3 tools/release/build_windows.py --release --steam-app-id <APPID>
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

from common.godot_cli import (  # noqa: E402
    require_godot_4_7_1,
    require_windows_export_templates,
    resolve_godot,
)
from release.package_verify import verify_package  # noqa: E402

PRODUCT = "DATE FACTORY"
VERSION = "1.0.0"
PRESET_NAME = "Windows Release"
SAVE_SCHEMA = 1
ZIP_NAME = f"DateFactory_{VERSION}_win64.zip"
GENERATED_STEAM_CFG = ROOT / "release" / "generated_steam_config.cfg"
GATE_PATH = ROOT / "release" / "release_gate.json"
NOTICES_SRC = ROOT / "release" / "THIRD_PARTY_NOTICES.txt"


def _run(cmd: list[str], *, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        cwd=str(cwd or ROOT),
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )


def git_commit_and_dirty() -> tuple[str, bool]:
    sha_proc = _run(["git", "rev-parse", "HEAD"])
    sha = (sha_proc.stdout or "").strip() if sha_proc.returncode == 0 else "UNKNOWN"
    dirty_proc = _run(["git", "status", "--porcelain"])
    dirty = False
    if dirty_proc.returncode == 0:
        for line in (dirty_proc.stdout or "").splitlines():
            # Ignore untracked build/dist noise if present; still count tracked mods.
            if not line.strip():
                continue
            # porcelain: XY path
            path = line[3:].strip() if len(line) > 3 else line
            if path.startswith("build/") or path.startswith("dist/") or path.startswith("tmp/"):
                continue
            dirty = True
            break
    return sha, dirty


def load_gate() -> dict[str, Any]:
    data = json.loads(GATE_PATH.read_text(encoding="utf-8"))
    return data


def assert_gate_clear(gate: dict[str, Any]) -> None:
    blocker = int(gate.get("blocker_open", 0))
    major = int(gate.get("major_open", 0))
    if blocker > 0 or major > 0:
        raise RuntimeError(
            f"release_gate.json not clear: blocker_open={blocker} major_open={major}"
        )


def write_steam_config(app_id: int) -> None:
    GENERATED_STEAM_CFG.parent.mkdir(parents=True, exist_ok=True)
    GENERATED_STEAM_CFG.write_text(
        "[steam]\n"
        f"app_id={int(app_id)}\n",
        encoding="utf-8",
    )


def cleanup_steam_config() -> None:
    if GENERATED_STEAM_CFG.exists():
        GENERATED_STEAM_CFG.unlink()


def _project_godot_path() -> Path:
    return ROOT / "project.godot"


def prepare_project_for_export() -> str:
    """Disable GodotIQ editor plugin for export so it cannot re-add GodotIQRuntime.

    GodotIQ's editor plugin calls add_autoload_singleton(GodotIQRuntime) on enable.
    If that runs during --export-release while addons/godotiq is excluded, the
    packaged game gets a broken empty autoload path. Returns original project.godot
    text for restore.
    """
    path = _project_godot_path()
    original = path.read_text(encoding="utf-8")
    text = original
    # Drop any GodotIQRuntime autoload line.
    lines = [
        ln
        for ln in text.splitlines(keepends=True)
        if not ln.startswith("GodotIQRuntime=")
    ]
    text = "".join(lines)
    # Keep addon on disk for Cursor, but do not enable plugin during export.
    text = text.replace(
        'enabled=PackedStringArray("res://addons/godotiq/plugin.cfg")',
        'enabled=PackedStringArray()',
    )
    # Also handle multi-plugin arrays that include godotiq.
    if "addons/godotiq/plugin.cfg" in text and "enabled=PackedStringArray()" not in text:
        import re

        def _strip_godotiq(match: "re.Match[str]") -> str:
            inner = match.group(1)
            parts = [p.strip() for p in inner.split(",") if p.strip()]
            kept = [p for p in parts if "godotiq" not in p.lower()]
            return "enabled=PackedStringArray(" + ", ".join(kept) + ")"

        text = re.sub(
            r"enabled=PackedStringArray\((.*?)\)",
            _strip_godotiq,
            text,
            count=1,
        )
    path.write_text(text, encoding="utf-8")
    return original


def restore_project_godot(original: str | None) -> None:
    if original is None:
        return
    _project_godot_path().write_text(original, encoding="utf-8")


def run_rc_qa(godot: Path) -> dict[str, Any]:
    cmd = [
        sys.executable,
        str(ROOT / "tools" / "qa" / "run_all_tests.py"),
        "--only-rc",
        "--godot",
        str(godot),
    ]
    print("Running RC QA:", " ".join(cmd))
    proc = subprocess.run(cmd, cwd=str(ROOT), check=False)
    summary_path = ROOT / "tmp" / "qa" / "summary.txt"
    summary_text = summary_path.read_text(encoding="utf-8") if summary_path.is_file() else ""
    required = passed = failed = 0
    for line in summary_text.splitlines():
        if line.startswith("TOTAL "):
            required = int(line.split()[1])
        elif line.startswith("PASS  ") and line[5:].strip().isdigit():
            passed = int(line.split()[1])
        elif line.startswith("FAIL  ") and line[5:].strip().isdigit():
            failed = int(line.split()[1])
    result = {
        "exit_code": int(proc.returncode),
        "qa_required": required,
        "qa_passed": passed,
        "qa_failed": failed,
        "summary_path": str(summary_path),
    }
    if proc.returncode != 0:
        raise RuntimeError(f"RC QA failed (exit={proc.returncode}). See {summary_path}")
    return result


def clean_staging(staging: Path) -> None:
    if staging.exists():
        shutil.rmtree(staging)
    staging.mkdir(parents=True, exist_ok=True)
    (ROOT / "build" / "logs").mkdir(parents=True, exist_ok=True)
    (ROOT / "dist").mkdir(parents=True, exist_ok=True)


def export_windows(godot: Path, staging_exe: Path, log_path: Path) -> None:
    staging_exe.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        str(godot),
        "--headless",
        "--path",
        str(ROOT),
        "--export-release",
        PRESET_NAME,
        str(staging_exe),
    ]
    print("Export:", " ".join(cmd))
    proc = _run(cmd)
    log_path.write_text(
        (proc.stdout or "") + "\n" + (proc.stderr or ""),
        encoding="utf-8",
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"Export failed exit={proc.returncode}. Log: {log_path}"
        )
    if not staging_exe.is_file():
        raise RuntimeError(f"Export claimed success but missing exe: {staging_exe}")


def copy_notices(staging: Path) -> None:
    if not NOTICES_SRC.is_file():
        raise RuntimeError(f"Missing notices: {NOTICES_SRC}")
    shutil.copy2(NOTICES_SRC, staging / "THIRD_PARTY_NOTICES.txt")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            chunk = f.read(1024 * 1024)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def make_zip(staging: Path, zip_path: Path) -> None:
    if zip_path.exists():
        zip_path.unlink()
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for path in staging.rglob("*"):
            if path.is_file():
                arc = Path("DateFactory") / path.relative_to(staging)
                zf.write(path, arcname=arc.as_posix())


def write_manifest(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def print_success(manifest: dict[str, Any]) -> None:
    store = "PENDING EXTERNAL TASKS"
    if manifest.get("steam_app_id_configured") and manifest.get("code_signed"):
        store = "READY"
    print("")
    print("DATE FACTORY RELEASE BUILD")
    print("")
    print(f"Version: {manifest['version']}")
    print(f"Commit: {manifest['git_commit']}")
    print(f"Godot: {manifest['godot_version']}")
    print("Platform: Windows x86_64")
    print("")
    print(f"QA: {manifest['qa_passed']}/{manifest['qa_required']} PASS")
    print(f"Blocker: {manifest['known_open_blocker']}")
    print(f"Major: {manifest['known_open_major']}")
    print("")
    print("Steam: integrated")
    print(
        "Steam AppID: configured"
        if manifest["steam_app_id_configured"]
        else "Steam AppID: not configured"
    )
    print("Signing: signed" if manifest["code_signed"] else "Signing: unsigned")
    print("")
    print("Artifact:")
    print(f"dist/{ZIP_NAME}")
    print("")
    print("SHA256:")
    print(manifest["sha256"])
    print("")
    print("TECHNICAL RELEASE READY")
    print(f"STORE RELEASE: {store}")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Build DATE FACTORY Windows release package")
    p.add_argument("--godot", default=None, help="Godot executable path")
    p.add_argument("--release", action="store_true", help="Run RC QA + release gates")
    p.add_argument(
        "--allow-dirty",
        action="store_true",
        help="Allow dirty tracked tree on --release (recorded in manifest)",
    )
    p.add_argument(
        "--steam-app-id",
        type=int,
        default=0,
        help="Optional Steam AppID for generated export config (not invented by default)",
    )
    p.add_argument(
        "--skip-qa",
        action="store_true",
        help="Skip RC QA even with --release (debug only; not for final gate)",
    )
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    staging = ROOT / "build" / "staging" / "windows"
    # Export path in preset defaults to build/windows/; we stage under staging then copy.
    export_exe = ROOT / "build" / "windows" / "DateFactory.exe"
    log_path = ROOT / "build" / "logs" / "export_windows.log"
    dist_zip = ROOT / "dist" / ZIP_NAME
    dist_sha = ROOT / "dist" / f"{ZIP_NAME}.sha256"
    dist_manifest = ROOT / "dist" / "release_manifest.json"

    steam_app_id = int(args.steam_app_id or 0)
    env_app = os.environ.get("DATE_FACTORY_STEAM_APP_ID", "").strip()
    if steam_app_id <= 0 and env_app.isdigit():
        steam_app_id = int(env_app)

    try:
        godot = resolve_godot(args.godot)
        godot_version = require_godot_4_7_1(godot)
        require_windows_export_templates()
        gate = load_gate()
        assert_gate_clear(gate)

        git_sha, dirty = git_commit_and_dirty()
        if args.release and dirty and not args.allow_dirty:
            raise RuntimeError(
                "Dirty tracked working tree. Commit/stash first, or pass --allow-dirty "
                "(dirty status will be recorded in release_manifest.json)."
            )

        qa_info = {
            "qa_required": 0,
            "qa_passed": 0,
            "qa_failed": 0,
        }
        if args.release and not args.skip_qa:
            qa_info = run_rc_qa(godot)

        if steam_app_id > 0:
            write_steam_config(steam_app_id)
        else:
            cleanup_steam_config()

        clean_staging(staging)
        # Clean default export dir too.
        export_dir = export_exe.parent
        if export_dir.exists():
            shutil.rmtree(export_dir)
        export_dir.mkdir(parents=True, exist_ok=True)

        project_backup: str | None = None
        try:
            project_backup = prepare_project_for_export()
            export_windows(godot, export_exe, log_path)
            # Move/copy export outputs into clean staging.
            for item in export_dir.iterdir():
                dest = staging / item.name
                if item.is_dir():
                    shutil.copytree(item, dest)
                else:
                    shutil.copy2(item, dest)
            copy_notices(staging)
            errors = verify_package(staging)
            if errors:
                raise RuntimeError("Package verification failed:\n- " + "\n- ".join(errors))

            make_zip(staging, dist_zip)
            digest = sha256_file(dist_zip)
            dist_sha.write_text(f"{digest}  {ZIP_NAME}\n", encoding="utf-8")

            manifest = {
                "product": PRODUCT,
                "version": VERSION,
                "platform": "Windows",
                "arch": "x86_64",
                "godot_version": godot_version,
                "git_commit": git_sha,
                "git_dirty": dirty,
                "build_time_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                "save_schema": SAVE_SCHEMA,
                "qa_required": qa_info.get("qa_required", 0),
                "qa_passed": qa_info.get("qa_passed", 0),
                "steam_integration": True,
                "steam_app_id_configured": steam_app_id > 0,
                "code_signed": False,
                "signing_status": "UNSIGNED",
                "artifact": f"dist/{ZIP_NAME}",
                "sha256": digest,
                "known_open_blocker": int(gate.get("blocker_open", 0)),
                "known_open_major": int(gate.get("major_open", 0)),
                "accepted_minor_ids": list(gate.get("accepted_minor_ids", [])),
            }
            write_manifest(dist_manifest, manifest)
            # Also write machine-readable gate snapshot under build/.
            (ROOT / "build" / "release_gate_snapshot.json").write_text(
                json.dumps(
                    {
                        "blocker_open": manifest["known_open_blocker"],
                        "major_open": manifest["known_open_major"],
                        "accepted_minor_ids": manifest["accepted_minor_ids"],
                        "qa_required": manifest["qa_required"],
                        "qa_passed": manifest["qa_passed"],
                        "git_dirty": dirty,
                    },
                    indent=2,
                )
                + "\n",
                encoding="utf-8",
            )
            print_success(manifest)
            return 0
        finally:
            restore_project_godot(project_backup)
            cleanup_steam_config()
    except Exception as exc:  # noqa: BLE001 - top-level builder UX
        print(f"RELEASE BUILD FAIL: {exc}", file=sys.stderr)
        cleanup_steam_config()
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
