"""Shared absolute paths for DATE FACTORY Proxy POC pipeline."""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\User\Documents\GodotProjects\date_factory")
WORK_ROOT = Path(r"C:\Users\User\Downloads\date_factory_proxy_work")
PROXY_BLEND = Path(r"C:\Users\User\Downloads\assets\proxy_1.5.blend")
BLENDER_EXE = Path(r"C:\Program Files (x86)\Steam\steamapps\common\Blender\blender.exe")

UAL_GLB = PROJECT_ROOT / r"assets\animation\universal_library\source\UAL1_Standard.glb"
UAL_ALIASES = PROJECT_ROOT / r"assets\animation\universal_library\libraries\DF_UAL_Aliases.res"
UAL_CLIP_MAP = PROJECT_ROOT / r"assets\animation\universal_library\libraries\UAL_CLIP_MAP.json"
DONOR_GLTF = PROJECT_ROOT / r"assets\characters\hero_base\meshes\bodies\Superhero_Female_FullBody.gltf"
DATE_GIRL_UAL = PROJECT_ROOT / r"assets\characters\hero_base\prefabs\DateGirl_UAL.tscn"

REQUIRED_ALIASES = (
    "idle",
    "walk",
    "run",
    "sit_enter",
    "sit_idle",
    "seated_gesture",
    "sit_exit",
)

UAL_CLIP_NAMES = {
    "idle": "Idle",
    "walk": "Walk",
    "run": "Sprint",
    "sit_enter": "Sitting_Enter",
    "sit_idle": "Sitting_Idle",
    "seated_gesture": "Sitting_Talking",
    "sit_exit": "Sitting_Exit",
}


def ensure_dir(path: Path) -> Path:
    path.mkdir(parents=True, exist_ok=True)
    return path


def parse_argv_after_double_dash(argv: list[str] | None = None) -> list[str]:
    raw = list(sys.argv[1:] if argv is None else argv)
    if "--" in raw:
        return raw[raw.index("--") + 1 :]
    return raw


def add_common_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--proxy", type=Path, default=PROXY_BLEND)
    parser.add_argument("--output", type=Path, default=WORK_ROOT)
    parser.add_argument("--donor", type=Path, default=DONOR_GLTF)
    parser.add_argument("--ual", type=Path, default=UAL_GLB)
    parser.add_argument("--project", type=Path, default=PROJECT_ROOT)


def write_json(path: Path, data) -> None:
    ensure_dir(path.parent)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def log(msg: str) -> None:
    print(f"[PROXY_POC] {msg}", flush=True)


def fail(msg: str, code: int = 1) -> None:
    print(f"[PROXY_POC][FAIL] {msg}", flush=True)
    raise SystemExit(code)


def require_file(path: Path, label: str) -> Path:
    if not path.is_file():
        fail(f"Missing {label}: {path}")
    return path
