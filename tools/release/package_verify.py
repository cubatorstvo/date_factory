#!/usr/bin/env python3
"""Verify DATE FACTORY Windows release staging package contents."""

from __future__ import annotations

from pathlib import Path
from typing import Iterable


REQUIRED_FILES = (
    "DateFactory.exe",
    "DateFactory.pck",
    "THIRD_PARTY_NOTICES.txt",
)

# GodotSteam / Steamworks Windows x86_64 redistributables (actual upstream names).
REQUIRED_DLL_SUBSTRINGS = (
    "steam_api64.dll",
    "libgodotsteam.windows.template_release.x86_64.dll",
)

FORBIDDEN_NAME_FRAGMENTS = (
    "steam_appid.txt",
    "godotiq",
    ".cursor",
    ".godotiq",
    "GodotIQRuntime",
)


def _iter_files(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if path.is_file():
            yield path


def verify_package(staging_dir: Path) -> list[str]:
    """Return list of error strings; empty means PASS."""
    errors: list[str] = []
    if not staging_dir.is_dir():
        return [f"staging dir missing: {staging_dir}"]

    for name in REQUIRED_FILES:
        if not (staging_dir / name).is_file():
            errors.append(f"missing required file: {name}")

    names_lower = [p.name.lower() for p in _iter_files(staging_dir)]
    for needle in REQUIRED_DLL_SUBSTRINGS:
        if not any(needle.lower() == n or needle.lower() in n for n in names_lower):
            # Also accept DLL living in a subdirectory.
            found = any(needle.lower() in p.name.lower() for p in _iter_files(staging_dir))
            if not found:
                errors.append(f"missing required DLL/native: {needle}")

    for path in _iter_files(staging_dir):
        rel = path.relative_to(staging_dir).as_posix().lower()
        name = path.name.lower()
        for frag in FORBIDDEN_NAME_FRAGMENTS:
            f = frag.lower()
            if f in name or f in rel:
                errors.append(f"forbidden package content: {path.relative_to(staging_dir)}")
                break
        # Loose developer path smell in tiny text configs only.
        if path.suffix.lower() in {".cfg", ".txt", ".json", ".md"} and path.stat().st_size < 2_000_000:
            try:
                text = path.read_text(encoding="utf-8", errors="replace").lower()
            except OSError:
                continue
            if "c:\\users\\user\\downloads\\godot" in text:
                errors.append(f"developer absolute Godot path leaked into package: {path.name}")

    # Binary scan: GodotIQRuntime must not ship inside PCK/EXE.
    for binary_name in ("DateFactory.pck", "DateFactory.exe"):
        binary = staging_dir / binary_name
        if not binary.is_file():
            continue
        data = binary.read_bytes()
        if b"GodotIQRuntime" in data or b"addons/godotiq" in data:
            errors.append(f"{binary_name} still contains GodotIQ runtime/addon markers")

    return sorted(set(errors))
