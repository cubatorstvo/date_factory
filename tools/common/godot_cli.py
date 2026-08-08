#!/usr/bin/env python3
"""Portable Godot CLI resolver for DATE FACTORY tools.

Resolution order:
  1. explicit --godot / resolve_godot(cli_path=...)
  2. GODOT environment variable
  3. PATH: godot, then godot4

Does not hardcode machine-specific Download paths into committed tooling.
"""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path


def repo_root_from_here() -> Path:
    return Path(__file__).resolve().parents[2]


def resolve_godot(cli_godot: str | None = None) -> Path:
    candidates: list[str] = []
    if cli_godot:
        candidates.append(cli_godot)
    env = os.environ.get("GODOT")
    if env:
        candidates.append(env)
    for name in ("godot", "godot4"):
        found = shutil.which(name)
        if found:
            candidates.append(found)

    for candidate in candidates:
        path = Path(candidate)
        if path.is_file():
            return path.resolve()

    raise FileNotFoundError(
        "Godot executable not found. Pass --godot <path>, set GODOT, "
        "or place `godot`/`godot4` on PATH."
    )


def godot_version_string(godot: Path) -> str:
    completed = subprocess.run(
        [str(godot), "--version"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    out = ((completed.stdout or "") + (completed.stderr or "")).strip()
    if not out:
        raise RuntimeError(f"Godot --version produced no output: {godot}")
    return out.splitlines()[0].strip()


def require_godot_4_7_1(godot: Path) -> str:
    version = godot_version_string(godot)
    if "4.7.1" not in version:
        raise RuntimeError(
            f"Godot 4.7.1 required for release builds; got: {version}"
        )
    return version


def windows_export_templates_dir() -> Path:
    appdata = os.environ.get("APPDATA")
    if not appdata:
        raise RuntimeError("APPDATA is not set; cannot locate Godot export templates.")
    return Path(appdata) / "Godot" / "export_templates" / "4.7.1.stable"


def require_windows_export_templates() -> Path:
    template_dir = windows_export_templates_dir()
    release_tpl = template_dir / "windows_release_x86_64.exe"
    if not release_tpl.is_file():
        raise RuntimeError(
            "Missing Godot 4.7.1 Windows x86_64 release export templates.\n"
            f"Expected: {release_tpl}\n"
            "Install templates via Godot Editor → Editor → Manage Export Templates "
            "for 4.7.1.stable. This tool will not auto-download templates."
        )
    return template_dir
