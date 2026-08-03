#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""DATE FACTORY — selective asset import (does NOT modify source folder)."""

from __future__ import annotations

import json
import re
import shutil
from collections import defaultdict
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

SRC_ROOT = Path(r"C:\Users\User\Downloads\assets_audit\_temp")
# Never write to Downloads\assets
PROJECT = Path(r"C:\Users\User\Documents\GodotProjects\date_factory")
ASSETS = PROJECT / "assets"
SCENES_ART = PROJECT / "scenes" / "art"
DOCS = PROJECT / "docs"

FMT_PRIORITY = [".glb", ".gltf", ".fbx", ".obj"]

SKIP_NAME_RE = re.compile(
    r"(preview|readme|documentation|\.url$|\.html$|\.zip$|unity|unreal|"
    r"sample\.png|overview|visit |patreon|license\.txt)",
    re.I,
)

WEAPON_RE = re.compile(
    r"(^Gun_|^Prop_Ammo|^Prop_Grenade|^Prop_Mine|^Prop_Health|^Prop_Syringe)",
    re.I,
)
ANIMAL_RE = re.compile(r"(rabbit|panda|truck)", re.I)

LOG: dict = {
    "started": datetime.now(timezone.utc).isoformat(),
    "packs": {},
    "excluded_categories": [],
    "problems": [],
    "deferred": [],
    "copied_files": 0,
    "bytes": 0,
}


def ensure_dirs() -> None:
    paths = [
        ASSETS / "environment/city/downtown_megakit/meshes",
        ASSETS / "environment/city/downtown_megakit/materials",
        ASSETS / "environment/city/downtown_megakit/textures",
        ASSETS / "environment/city/downtown_megakit/scenes",
        ASSETS / "environment/interior/house_interior/meshes",
        ASSETS / "environment/interior/house_interior/materials",
        ASSETS / "environment/interior/house_interior/textures",
        ASSETS / "environment/interior/house_interior/scenes",
        ASSETS / "environment/restaurant/sushi_restaurant/meshes",
        ASSETS / "environment/restaurant/sushi_restaurant/materials",
        ASSETS / "environment/restaurant/sushi_restaurant/textures",
        ASSETS / "environment/restaurant/sushi_restaurant/scenes",
        ASSETS / "environment/factory/kenney_factory/meshes",
        ASSETS / "environment/factory/kenney_factory/materials",
        ASSETS / "environment/factory/kenney_factory/textures",
        ASSETS / "environment/factory/kenney_factory/scenes",
        ASSETS / "environment/lab/scifi_essentials/meshes",
        ASSETS / "environment/lab/scifi_essentials/materials",
        ASSETS / "environment/lab/scifi_essentials/textures",
        ASSETS / "environment/lab/scifi_essentials/scenes",
        ASSETS / "characters/women_modular/meshes",
        ASSETS / "characters/women_modular/materials",
        ASSETS / "characters/women_modular/textures",
        ASSETS / "characters/women_modular/prefabs",
        ASSETS / "characters/hero_base/meshes",
        ASSETS / "characters/hero_base/materials",
        ASSETS / "characters/hero_base/textures",
        ASSETS / "characters/hero_base/prefabs",
        ASSETS / "animation/universal_library/source",
        ASSETS / "animation/universal_library/libraries",
        ASSETS / "animation/universal_library/retargeted",
        ASSETS / "props/food/meshes",
        ASSETS / "props/food/materials",
        ASSETS / "props/food/textures",
        ASSETS / "props/food/scenes",
        ASSETS / "materials/base",
        SCENES_ART / "kits",
        SCENES_ART / "testbeds",
        SCENES_ART / "rooms",
        SCENES_ART / "city",
        SCENES_ART / "restaurant",
        SCENES_ART / "factory",
        SCENES_ART / "lab",
        SCENES_ART / "characters",
    ]
    for p in paths:
        p.mkdir(parents=True, exist_ok=True)


def copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists() and dst.stat().st_size == src.stat().st_size:
        return
    shutil.copy2(src, dst)
    LOG["copied_files"] += 1
    LOG["bytes"] += src.stat().st_size


def pick_unique_by_stem(files: Iterable[Path]) -> list[Path]:
    best: dict[str, Path] = {}
    rank = {e: i for i, e in enumerate(FMT_PRIORITY)}
    for f in files:
        stem = f.stem.lower()
        ext = f.suffix.lower()
        if ext not in rank:
            continue
        cur = best.get(stem)
        if cur is None or rank[ext] < rank[cur.suffix.lower()]:
            best[stem] = f
    return list(best.values())


def copy_tree_filtered(
    src_dir: Path,
    dst_dir: Path,
    *,
    allowed_exts: set[str],
    name_reject: re.Pattern | None = None,
    path_must_contain: list[str] | None = None,
    path_must_not_contain: list[str] | None = None,
    also_sidecar: set[str] | None = None,
) -> dict:
    """Copy models by preferred format + sidecars (.bin, textures referenced nearby)."""
    also_sidecar = also_sidecar or {".bin", ".png", ".jpg", ".jpeg"}
    stats = {"models": 0, "sidecars": 0, "skipped": 0}
    if not src_dir.exists():
        LOG["problems"].append(f"missing source: {src_dir}")
        return stats

    candidates: list[Path] = []
    for f in src_dir.rglob("*"):
        if not f.is_file():
            continue
        rel = str(f.relative_to(src_dir)).replace("\\", "/")
        low = rel.lower()
        if SKIP_NAME_RE.search(low) or SKIP_NAME_RE.search(f.name):
            stats["skipped"] += 1
            continue
        if path_must_contain and not any(p.lower() in low for p in path_must_contain):
            continue
        if path_must_not_contain and any(p.lower() in low for p in path_must_not_contain):
            stats["skipped"] += 1
            continue
        if name_reject and name_reject.search(f.name):
            stats["skipped"] += 1
            continue
        if f.suffix.lower() in allowed_exts:
            candidates.append(f)

    chosen = pick_unique_by_stem(candidates)
    for model in chosen:
        rel = model.relative_to(src_dir)
        dst = dst_dir / rel
        # flatten nested format folders a bit for food/interior
        copy_file(model, dst)
        stats["models"] += 1
        # sidecars same stem
        for side in model.parent.iterdir():
            if not side.is_file():
                continue
            if side.stem == model.stem and side.suffix.lower() in also_sidecar:
                copy_file(side, dst.parent / side.name)
                stats["sidecars"] += 1
        # textures often co-located in glTF folders
        for tex in model.parent.glob("*.png"):
            copy_file(tex, dst.parent / tex.name)
            stats["sidecars"] += 1
        for tex in model.parent.glob("*.jpg"):
            copy_file(tex, dst.parent / tex.name)
            stats["sidecars"] += 1
    return stats


def import_pack_001() -> None:
    root = SRC_ROOT / "PACK_001"
    dst_m = ASSETS / "environment/city/downtown_megakit/meshes"
    dst_t = ASSETS / "environment/city/downtown_megakit/textures"
    st = copy_tree_filtered(
        root / "Exports" / "glTF (Godot)",
        dst_m,
        allowed_exts={".gltf", ".glb"},
        path_must_not_contain=["FBX (Unity)", "FBX (Unreal"],
    )
    # textures folder (skip Unreal-Normals duplicates if possible — take main Textures)
    tex_src = root / "Textures"
    if tex_src.exists():
        for f in tex_src.rglob("*"):
            if not f.is_file():
                continue
            if "unreal" in str(f).lower():
                continue
            if f.suffix.lower() not in {".png", ".jpg", ".jpeg", ".hdr"}:
                continue
            if SKIP_NAME_RE.search(f.name):
                continue
            rel = f.relative_to(tex_src)
            copy_file(f, dst_t / rel)
    # license
    lic = root / "License_Standard.txt"
    if lic.exists():
        copy_file(lic, ASSETS / "environment/city/downtown_megakit/LICENSE.txt")
    LOG["packs"]["PACK_001"] = {
        "format": "gltf (Godot)",
        "dest": str(dst_m.relative_to(PROJECT)),
        **st,
        "excluded": ["FBX Unity", "FBX Unreal", "Previews", "Unreal-Normals"],
    }


def import_pack_002() -> None:
    root = SRC_ROOT / "PACK_002"
    dst = ASSETS / "environment/factory/kenney_factory/meshes"
    # Prefer GLB only — skip FBX/OBJ duplicates
    keep = re.compile(
        r"(conveyor|machine|pipe|tank|box|platform|robot|catwalk|cog|cylinder|"
        r"container|structure|wall|floor|set|button|ladder|support|rail|door|"
        r"fence|slope|tower|vent|wheel|motor|barrel)",
        re.I,
    )
    src = root / "Models" / "GLB format"
    stats = {"models": 0, "skipped": 0}
    if src.exists():
        for f in src.glob("*.glb"):
            if not keep.search(f.stem):
                stats["skipped"] += 1
                continue
            copy_file(f, dst / f.name)
            stats["models"] += 1
    # GLBs reference Textures/colormap.png relative to the GLB folder.
    for tex_src in [
        root / "Models" / "GLB format" / "Textures",
        root / "Models" / "Textures",
    ]:
        if not tex_src.exists():
            continue
        for f in tex_src.rglob("*.png"):
            copy_file(f, dst / "Textures" / f.name)
            copy_file(f, ASSETS / "environment/factory/kenney_factory/textures" / f.name)
    lic = root / "License.txt"
    if lic.exists():
        copy_file(lic, ASSETS / "environment/factory/kenney_factory/LICENSE.txt")
    LOG["packs"]["PACK_002"] = {
        "format": "glb",
        "dest": str(dst.relative_to(PROJECT)),
        **stats,
        "excluded": ["FBX", "OBJ", "Previews", "urls", "html", "non-factory stems"],
    }


def import_pack_015() -> None:
    root = SRC_ROOT / "PACK_015"
    dst = ASSETS / "environment/lab/scifi_essentials/meshes"
    st = copy_tree_filtered(
        root / "glTF",
        dst,
        allowed_exts={".gltf", ".glb"},
        name_reject=WEAPON_RE,
    )
    # also copy shared textures from glTF root that weren't per-model
    for f in (root / "glTF").glob("T_*.png"):
        if WEAPON_RE.search(f.name) or "Guns" in f.name or "Ammo" in f.name:
            continue
        copy_file(f, dst / f.name)
    # Textures folder
    tsrc = root / "Textures"
    if tsrc.exists():
        for f in tsrc.rglob("*.png"):
            if "Guns" in f.name or "Ammo" in f.name:
                continue
            copy_file(f, ASSETS / "environment/lab/scifi_essentials/textures" / f.name)
    lic = root / "License_Standard.txt"
    if lic.exists():
        copy_file(lic, ASSETS / "environment/lab/scifi_essentials/LICENSE.txt")
    LOG["packs"]["PACK_015"] = {
        "format": "gltf",
        "dest": str(dst.relative_to(PROJECT)),
        **st,
        "excluded": ["weapons", "ammo", "grenades", "mines", "health packs", "FBX Unity", "OBJ"],
    }


def import_pack_016() -> None:
    root = SRC_ROOT / "PACK_016" / "Sushi Restaurant Kit - May 2023"
    dst = ASSETS / "environment/restaurant/sushi_restaurant/meshes"
    stats = {"models": 0, "skipped": 0}
    for sub in ["Environment", "Decoration", "Food"]:
        gdir = root / sub / "glTF"
        if not gdir.exists():
            # some packs nest differently
            gdir = root / sub
        for f in gdir.rglob("*.gltf"):
            if ANIMAL_RE.search(f.name):
                stats["skipped"] += 1
                continue
            if "Characters" in str(f):
                stats["skipped"] += 1
                continue
            rel = Path(sub) / f.name
            copy_file(f, dst / rel)
            stats["models"] += 1
            for side in f.parent.iterdir():
                if side.is_file() and side.stem == f.stem and side.suffix.lower() in {".bin", ".png", ".jpg"}:
                    copy_file(side, dst / Path(sub) / side.name)
                elif side.is_file() and side.suffix.lower() in {".png", ".jpg"}:
                    copy_file(side, dst / Path(sub) / side.name)
    LOG["packs"]["PACK_016"] = {
        "format": "gltf",
        "dest": str(dst.relative_to(PROJECT)),
        **stats,
        "excluded": ["Characters", "rabbits", "panda", "truck", "blend", "fbx", "obj"],
        "license": "undefined in source audit",
    }


def import_pack_017() -> None:
    root = SRC_ROOT / "PACK_017" / "Ultimate Food Pack - Oct 2019"
    dst = ASSETS / "props/food/meshes"
    st = copy_tree_filtered(
        root / "FBX",
        dst,
        allowed_exts={".fbx"},
    )
    # shared texture if any
    for f in root.rglob("*.png"):
        if "preview" in f.name.lower():
            continue
        copy_file(f, ASSETS / "props/food/textures" / f.name)
    lic = root / "License.txt"
    if lic.exists():
        copy_file(lic, ASSETS / "props/food/LICENSE.txt")
    LOG["packs"]["PACK_017"] = {
        "format": "fbx (no gltf/glb available)",
        "dest": str(dst.relative_to(PROJECT)),
        **st,
        "excluded": ["blend", "obj", "previews"],
    }


def import_pack_018() -> None:
    root = SRC_ROOT / "PACK_018" / "Ultimate House Interior Pack - June 2020"
    dst = ASSETS / "environment/interior/house_interior/meshes"
    st = copy_tree_filtered(
        root / "FBX",
        dst,
        allowed_exts={".fbx"},
    )
    for f in root.rglob("*.jpg"):
        if "preview" in f.name.lower():
            continue
        copy_file(f, ASSETS / "environment/interior/house_interior/textures" / f.name)
    lic = root / "License.txt"
    if lic.exists():
        copy_file(lic, ASSETS / "environment/interior/house_interior/LICENSE.txt")
    LOG["packs"]["PACK_018"] = {
        "format": "fbx (no gltf/glb available)",
        "dest": str(dst.relative_to(PROJECT)),
        **st,
        "excluded": ["blend", "obj", "previews"],
    }


def import_pack_019() -> None:
    root = SRC_ROOT / "PACK_019" / "Ultimate Modular Women - April 2022"
    dst = ASSETS / "characters/women_modular/meshes"
    # Individual Characters glTF only
    st = copy_tree_filtered(
        root / "Individual Characters" / "glTF",
        dst / "individuals",
        allowed_exts={".gltf", ".glb"},
    )
    # Also Humanoid Rigs if useful (fbx animations) — skip blend
    hr = root / "Humanoid Rigs"
    if hr.exists():
        for f in hr.rglob("*.fbx"):
            if "unity" in str(f).lower():
                continue
            copy_file(f, dst / "humanoid_rigs" / f.name)
    lic = root / "License.txt"
    if lic.exists():
        copy_file(lic, ASSETS / "characters/women_modular/LICENSE.txt")
    for f in root.rglob("*.jpg"):
        if "preview" in f.name.lower() or "readme" in f.name.lower():
            continue
        copy_file(f, ASSETS / "characters/women_modular/textures" / f.name)
    LOG["packs"]["PACK_019"] = {
        "format": "gltf individuals (+ humanoid fbx rigs)",
        "dest": str(dst.relative_to(PROJECT)),
        **st,
        "excluded": ["blend", "All together demos", "FBX character duplicates"],
    }


def import_pack_020() -> None:
    root = SRC_ROOT / "PACK_020" / "Universal Animation Library[Standard]"
    dst = ASSETS / "animation/universal_library/source"
    # Prefer Unreal-Godot GLB, skip Unity
    ug = root / "Unreal-Godot"
    stats = {"models": 0}
    if ug.exists():
        for f in ug.glob("*.glb"):
            copy_file(f, dst / f.name)
            stats["models"] += 1
    for f in root.glob("*.txt"):
        if "license" in f.name.lower():
            copy_file(f, ASSETS / "animation/universal_library/LICENSE.txt")
    for f in root.glob("*.png"):
        copy_file(f, ASSETS / "animation/universal_library/source" / f.name)
    LOG["packs"]["PACK_020"] = {
        "format": "glb (Unreal-Godot)",
        "dest": str(dst.relative_to(PROJECT)),
        **stats,
        "excluded": ["Unity folder", "FBX duplicates"],
    }


def import_pack_021() -> None:
    root = SRC_ROOT / "PACK_021" / "Universal Base Characters[Standard]"
    dst = ASSETS / "characters/hero_base/meshes"
    st = copy_tree_filtered(
        root / "Base Characters" / "Godot - UE",
        dst / "bodies",
        allowed_exts={".gltf", ".glb"},
    )
    # hairstyles
    hair = root / "Hairstyles"
    if hair.exists():
        st2 = copy_tree_filtered(
            hair,
            dst / "hairstyles",
            allowed_exts={".gltf", ".glb", ".fbx"},
        )
    else:
        st2 = {"models": 0}
    tex = root / "Base Characters" / "Textures"
    if tex.exists():
        for f in tex.rglob("*.png"):
            # prefer Godot normals path; skip double if same name
            copy_file(f, ASSETS / "characters/hero_base/textures" / f.name)
    lic = root / "License_Standard.txt"
    if lic.exists():
        copy_file(lic, ASSETS / "characters/hero_base/LICENSE.txt")
    LOG["packs"]["PACK_021"] = {
        "format": "gltf (Godot-UE)",
        "dest": str(dst.relative_to(PROJECT)),
        "bodies": st,
        "hairstyles": st2,
        "excluded": ["Unity-only paths", "FBX body duplicates where gltf exists"],
    }


def write_base_materials() -> list[str]:
    mat_dir = ASSETS / "materials/base"
    mats = {
        "City_Base_Concrete.tres": ("StandardMaterial3D", (0.55, 0.55, 0.52), 0.85, 0.0),
        "City_Base_Asphalt.tres": ("StandardMaterial3D", (0.12, 0.12, 0.13), 0.9, 0.0),
        "City_Base_Brick.tres": ("StandardMaterial3D", (0.55, 0.32, 0.22), 0.8, 0.0),
        "City_Base_Glass.tres": ("StandardMaterial3D", (0.55, 0.7, 0.8), 0.05, 0.85),
        "City_Base_Metal.tres": ("StandardMaterial3D", (0.45, 0.45, 0.48), 0.35, 0.7),
        "Interior_Base_WoodLight.tres": ("StandardMaterial3D", (0.72, 0.58, 0.4), 0.75, 0.05),
        "Interior_Base_WoodDark.tres": ("StandardMaterial3D", (0.35, 0.22, 0.14), 0.7, 0.05),
        "Interior_Base_Fabric.tres": ("StandardMaterial3D", (0.55, 0.5, 0.48), 0.95, 0.0),
        "Interior_Base_Plastic.tres": ("StandardMaterial3D", (0.85, 0.85, 0.86), 0.55, 0.1),
        "Interior_Base_WallPaint.tres": ("StandardMaterial3D", (0.9, 0.88, 0.84), 0.9, 0.0),
        "Interior_Base_Metal.tres": ("StandardMaterial3D", (0.6, 0.6, 0.62), 0.4, 0.65),
        "Interior_Base_Glass.tres": ("StandardMaterial3D", (0.7, 0.8, 0.85), 0.05, 0.8),
        "Restaurant_Base_WoodWarm.tres": ("StandardMaterial3D", (0.62, 0.42, 0.28), 0.65, 0.15),
        "Restaurant_Base_Lacquer.tres": ("StandardMaterial3D", (0.45, 0.28, 0.18), 0.35, 0.45),
        "Restaurant_Base_FabricWarm.tres": ("StandardMaterial3D", (0.65, 0.35, 0.32), 0.92, 0.0),
        "Restaurant_Base_Ceramic.tres": ("StandardMaterial3D", (0.92, 0.9, 0.86), 0.45, 0.05),
        "Restaurant_Base_Glass.tres": ("StandardMaterial3D", (0.75, 0.85, 0.9), 0.05, 0.85),
        "Restaurant_Base_KitchenMetal.tres": ("StandardMaterial3D", (0.7, 0.72, 0.74), 0.3, 0.8),
        "Factory_Base_DarkMetal.tres": ("StandardMaterial3D", (0.22, 0.24, 0.26), 0.45, 0.75),
        "Factory_Base_Plastic.tres": ("StandardMaterial3D", (0.75, 0.76, 0.78), 0.55, 0.15),
        "Factory_Base_AccentPink.tres": ("StandardMaterial3D", (0.85, 0.35, 0.55), 0.5, 0.2),
        "Factory_Base_Warning.tres": ("StandardMaterial3D", (0.85, 0.7, 0.15), 0.55, 0.1),
        "Lab_Base_WhitePlastic.tres": ("StandardMaterial3D", (0.92, 0.93, 0.95), 0.5, 0.1),
        "Lab_Base_ColdMetal.tres": ("StandardMaterial3D", (0.55, 0.6, 0.68), 0.35, 0.8),
        "Lab_Base_Glass.tres": ("StandardMaterial3D", (0.6, 0.75, 0.9), 0.05, 0.85),
        "Lab_Base_DarkPanel.tres": ("StandardMaterial3D", (0.12, 0.14, 0.18), 0.6, 0.4),
        "Lab_Base_Glow.tres": ("StandardMaterial3D", (0.45, 0.35, 0.85), 0.4, 0.3),
    }
    created = []
    for name, (_t, albedo, rough, metal) in mats.items():
        r, g, b = albedo
        # emission for glow
        emission = ""
        if "Glow" in name:
            emission = (
                f"emission_enabled = true\n"
                f"emission = Color({r}, {g}, {b}, 1)\n"
                f"emission_energy_multiplier = 1.8\n"
            )
        transparency = ""
        if "Glass" in name:
            transparency = "transparency = 1\n"
        content = (
            f"[gd_resource type=\"StandardMaterial3D\" format=3]\n\n"
            f"[resource]\n"
            f"resource_name = \"{name.replace('.tres', '')}\"\n"
            f"{transparency}"
            f"albedo_color = Color({r}, {g}, {b}, 1)\n"
            f"roughness = {rough}\n"
            f"metallic = {metal}\n"
            f"{emission}"
        )
        path = mat_dir / name
        path.write_text(content, encoding="utf-8")
        created.append(str(path.relative_to(PROJECT)).replace("\\", "/"))
    return created


def write_placeholder_prefab(path: Path, title: str, color: tuple[float, float, float], height: float = 1.7) -> None:
    r, g, b = color
    # Simple capsule mannequin prefab until editor reimports external meshes.
    # Also references intended source mesh path in metadata comment via node name.
    content = f"""[gd_scene load_steps=4 format=3]

[sub_resource type="CapsuleMesh" id="CapsuleMesh_1"]
radius = 0.28
height = {height}

[sub_resource type="StandardMaterial3D" id="Mat_1"]
albedo_color = Color({r}, {g}, {b}, 1)
roughness = 0.7

[sub_resource type="CapsuleShape3D" id="Shape_1"]
radius = 0.28
height = {height}

[node name="{path.stem}" type="CharacterBody3D"]
collision_layer = 2

[node name="Mesh" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {height * 0.5}, 0)
mesh = SubResource("CapsuleMesh_1")
surface_material_override/0 = SubResource("Mat_1")

[node name="Collision" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {height * 0.5}, 0)
shape = SubResource("Shape_1")

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]

[node name="Label" type="Label3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {height + 0.15}, 0)
text = "{title}"
font_size = 18
"""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def write_animation_library_stub() -> str:
    """Document clip remapping; actual AnimationLibrary binds after Godot imports GLB."""
    path = ASSETS / "animation/universal_library/libraries/UAL_CLIP_MAP.json"
    mapping = {
        "source": "res://assets/animation/universal_library/source/UAL1_Standard.glb",
        "source_rm": "res://assets/animation/universal_library/source/UAL1_Standard_RM.glb",
        "required_aliases": {
            "idle": ["Idle", "idle", "Idle_Loop"],
            "walk": ["Walk", "walk", "Walking"],
            "run": ["Run", "run", "Running"],
            "sit": ["Sit", "sit", "Sitting"],
            "stand": ["Stand", "stand", "StandUp", "stand_up"],
            "gesture": ["Gesture", "Talk", "Wave", "Point"],
            "react": ["React", "HitReact", "Surprised", "Confused", "Angry"],
        },
        "note": "After editor import, bind clips from UAL1_Standard*.glb into AnimationPlayer on character prefabs.",
    }
    path.write_text(json.dumps(mapping, indent=2), encoding="utf-8")
    return str(path.relative_to(PROJECT)).replace("\\", "/")


def write_kit_index_scene(name: str, mesh_dir: Path, out_path: Path, limit: int = 24) -> int:
    """Grid of MeshInstance placeholders referencing external scenes when possible."""
    models: list[Path] = []
    for ext in (".glb", ".gltf", ".fbx"):
        models.extend(sorted(mesh_dir.rglob(f"*{ext}")))
    # unique stems
    seen = set()
    picked = []
    for m in models:
        if m.stem in seen:
            continue
        seen.add(m.stem)
        picked.append(m)
        if len(picked) >= limit:
            break

    lines = ["[gd_scene load_steps=%d format=3]\n" % (len(picked) + 1)]
    for i, m in enumerate(picked, 1):
        res = "res://" + str(m.relative_to(PROJECT)).replace("\\", "/")
        lines.append(f'[ext_resource type="PackedScene" path="{res}" id="{i}"]\n')
    lines.append('\n[node name="%s" type="Node3D"]\n' % name)
    cols = 6
    for i, m in enumerate(picked):
        x = (i % cols) * 2.5
        z = (i // cols) * 2.5
        lines.append(
            f'\n[node name="{m.stem}" parent="." instance=ExtResource("{i+1}")]\n'
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:.1f}, 0, {z:.1f})\n"
        )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("".join(lines), encoding="utf-8")
    return len(picked)


def write_blockout_scene(path: Path, title: str, floor_color: tuple, props: list[tuple[str, float, float, float, float, float, float]]) -> None:
    """props: (name, x, y, z, sx, sy, sz) as boxes for layout; plus floor."""
    r, g, b = floor_color
    load_steps = 3 + len(props) * 2
    lines = [f'[gd_scene load_steps={load_steps} format=3]\n\n']
    lines.append('[sub_resource type="BoxMesh" id="FloorMesh"]\nsize = Vector3(16, 0.2, 16)\n\n')
    lines.append(
        f'[sub_resource type="StandardMaterial3D" id="FloorMat"]\nalbedo_color = Color({r}, {g}, {b}, 1)\nroughness = 0.85\n\n'
    )
    for i, (name, _x, _y, _z, sx, sy, sz) in enumerate(props):
        lines.append(f'[sub_resource type="BoxMesh" id="Box_{i}"]\nsize = Vector3({sx}, {sy}, {sz})\n\n')
        shade = 0.35 + (i % 5) * 0.1
        lines.append(
            f'[sub_resource type="StandardMaterial3D" id="Mat_{i}"]\n'
            f"albedo_color = Color({shade}, {shade * 0.9}, {shade * 0.95}, 1)\nroughness = 0.7\n\n"
        )
    lines.append(f'[node name="{path.stem}" type="Node3D"]\n\n')
    lines.append('[node name="WorldEnvHint" type="DirectionalLight3D" parent="."]\n')
    lines.append("transform = Transform3D(0.86, -0.35, 0.37, 0, 0.73, 0.68, -0.51, -0.59, 0.63, 4, 8, 4)\n")
    lines.append("shadow_enabled = true\n\n")
    lines.append('[node name="Floor" type="MeshInstance3D" parent="."]\n')
    lines.append("mesh = SubResource(\"FloorMesh\")\n")
    lines.append("surface_material_override/0 = SubResource(\"FloorMat\")\n\n")
    lines.append(f'[node name="Title" type="Label3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3.2, 0)\ntext = "{title}"\nfont_size = 28\n\n')
    for i, (name, x, y, z, sx, sy, sz) in enumerate(props):
        lines.append(f'[node name="{name}" type="MeshInstance3D" parent="."]\n')
        lines.append(f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, {y + sy * 0.5}, {z})\n")
        lines.append(f"mesh = SubResource(\"Box_{i}\")\n")
        lines.append(f"surface_material_override/0 = SubResource(\"Mat_{i}\")\n\n")
    # Marker nodes for kit instances (filled after reimport by artists)
    lines.append('[node name="KitAnchors" type="Node3D" parent="."]\n\n')
    lines.append('[node name="Spawn" type="Marker3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 4)\n')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(lines), encoding="utf-8")


def write_character_testbed() -> None:
    path = SCENES_ART / "testbeds" / "Character_Testbed.tscn"
    prefabs = [
        ("Hero", "res://assets/characters/hero_base/prefabs/Hero.tscn", -3, 0),
        ("Clone", "res://assets/characters/hero_base/prefabs/Clone.tscn", -1.5, 0),
        ("GirlCasual", "res://assets/characters/women_modular/prefabs/Girl_Casual.tscn", 0, 0),
        ("GirlFormal", "res://assets/characters/women_modular/prefabs/Girl_Formal.tscn", 1.5, 0),
        ("GirlWorker", "res://assets/characters/women_modular/prefabs/Girl_Worker.tscn", 3, 0),
        ("Manager", "res://assets/characters/women_modular/prefabs/Manager_Suit.tscn", 4.5, 0),
    ]
    lines = [f"[gd_scene load_steps={len(prefabs) + 1} format=3]\n\n"]
    for i, (name, res, _x, _z) in enumerate(prefabs, 1):
        lines.append(f'[ext_resource type="PackedScene" path="{res}" id="{i}"]\n')
    lines.append('\n[node name="Character_Testbed" type="Node3D"]\n\n')
    lines.append('[node name="Light" type="DirectionalLight3D" parent="."]\n')
    lines.append("transform = Transform3D(0.8, -0.4, 0.4, 0, 0.7, 0.7, -0.6, -0.55, 0.55, 2, 6, 3)\n\n")
    lines.append('[node name="Floor" type="CSGBox3D" parent="."]\n')
    lines.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.05, 0)\n")
    lines.append("size = Vector3(14, 0.1, 8)\n\n")
    lines.append('[node name="AnimNotes" type="Label3D" parent="."]\n')
    lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.8, -2)\n')
    lines.append('text = "Clips: idle walk run sit stand gesture react\\nSource: UAL1_Standard.glb"\n')
    lines.append("font_size = 18\n\n")
    for i, (name, _res, x, z) in enumerate(prefabs, 1):
        lines.append(f'[node name="{name}" parent="." instance=ExtResource("{i}")]\n')
        lines.append(f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, 0, {z})\n\n")
    path.write_text("".join(lines), encoding="utf-8")


def write_mesh_bridge_notes() -> None:
    """Map intended source meshes into kit scenes for next visual pass."""
    note = ASSETS / "IMPORT_MESH_INDEX.json"
    index = {
        "city": sorted(
            str(p.relative_to(PROJECT)).replace("\\", "/")
            for p in (ASSETS / "environment/city/downtown_megakit/meshes").rglob("*.gltf")
        )[:80],
        "factory": sorted(
            str(p.relative_to(PROJECT)).replace("\\", "/")
            for p in (ASSETS / "environment/factory/kenney_factory/meshes").rglob("*.glb")
        ),
        "lab": sorted(
            str(p.relative_to(PROJECT)).replace("\\", "/")
            for p in (ASSETS / "environment/lab/scifi_essentials/meshes").rglob("*.gltf")
        ),
        "restaurant": sorted(
            str(p.relative_to(PROJECT)).replace("\\", "/")
            for p in (ASSETS / "environment/restaurant/sushi_restaurant/meshes").rglob("*.gltf")
        )[:80],
        "interior": sorted(
            str(p.relative_to(PROJECT)).replace("\\", "/")
            for p in (ASSETS / "environment/interior/house_interior/meshes").rglob("*.fbx")
        )[:80],
        "food": sorted(
            str(p.relative_to(PROJECT)).replace("\\", "/")
            for p in (ASSETS / "props/food/meshes").rglob("*.fbx")
        )[:80],
        "women": sorted(
            str(p.relative_to(PROJECT)).replace("\\", "/")
            for p in (ASSETS / "characters/women_modular/meshes").rglob("*.gltf")
        ),
        "hero": sorted(
            str(p.relative_to(PROJECT)).replace("\\", "/")
            for p in (ASSETS / "characters/hero_base/meshes").rglob("*.gltf")
        ),
        "animation": sorted(
            str(p.relative_to(PROJECT)).replace("\\", "/")
            for p in (ASSETS / "animation/universal_library/source").rglob("*.glb")
        ),
    }
    note.write_text(json.dumps(index, indent=2), encoding="utf-8")


def main() -> None:
    print("== DATE FACTORY asset import ==")
    ensure_dirs()
    LOG["excluded_categories"] = [
        "PACK_013 mass import",
        "UI packs (003/005/012)",
        "audio/music packs",
        "format duplicates",
        "Unity/Unreal project trees",
        "demos/previews/zips",
        "weapons from PACK_015",
        "animals/truck from PACK_016 characters",
    ]
    LOG["deferred"] = [
        "PACK_013 small sample test",
        "Final AnimationLibrary .tres binding after editor import of UAL GLB",
        "Retarget women modular to UAL skeleton if needed",
        "Replace capsule prefabs with instanced imported characters after reimport",
    ]

    print("Importing packs...")
    import_pack_001()
    import_pack_002()
    import_pack_015()
    import_pack_016()
    import_pack_017()
    import_pack_018()
    import_pack_019()
    import_pack_020()
    import_pack_021()

    print("Materials...")
    mats = write_base_materials()
    LOG["materials"] = mats

    print("Prefabs...")
    prefab_paths = [
        (ASSETS / "characters/hero_base/prefabs/Hero.tscn", "Hero", (0.35, 0.55, 0.85)),
        (ASSETS / "characters/hero_base/prefabs/Clone.tscn", "Clone", (0.45, 0.75, 0.9)),
        (ASSETS / "characters/women_modular/prefabs/Girl_Casual.tscn", "Casual", (0.9, 0.55, 0.6)),
        (ASSETS / "characters/women_modular/prefabs/Girl_Formal.tscn", "Formal", (0.55, 0.4, 0.7)),
        (ASSETS / "characters/women_modular/prefabs/Girl_Worker.tscn", "Worker", (0.7, 0.65, 0.4)),
        (ASSETS / "characters/women_modular/prefabs/Manager_Suit.tscn", "Manager", (0.4, 0.4, 0.45)),
    ]
    for p, title, col in prefab_paths:
        write_placeholder_prefab(p, title, col)
    LOG["prefabs"] = [str(p.relative_to(PROJECT)).replace("\\", "/") for p, _, _ in prefab_paths]
    LOG["prefab_note"] = (
        "Capsule stand-ins with AnimationPlayer; intended mesh sources: "
        "Hero/Clone -> PACK_021 Superhero_Male; girls -> PACK_019 Casual/Formal/Worker; "
        "Manager -> PACK_019 Suit. Swap Mesh after Godot imports glTF."
    )

    clip_map = write_animation_library_stub()
    LOG["animation_map"] = clip_map

    print("Kit indexes...")
    LOG["kit_scenes"] = {
        "city": write_kit_index_scene(
            "City_Kit_Index",
            ASSETS / "environment/city/downtown_megakit/meshes",
            SCENES_ART / "kits" / "City_Kit_Index.tscn",
            30,
        ),
        "factory": write_kit_index_scene(
            "Factory_Kit_Index",
            ASSETS / "environment/factory/kenney_factory/meshes",
            SCENES_ART / "kits" / "Factory_Kit_Index.tscn",
            30,
        ),
        "lab": write_kit_index_scene(
            "Lab_Kit_Index",
            ASSETS / "environment/lab/scifi_essentials/meshes",
            SCENES_ART / "kits" / "Lab_Kit_Index.tscn",
            24,
        ),
        "restaurant": write_kit_index_scene(
            "Restaurant_Kit_Index",
            ASSETS / "environment/restaurant/sushi_restaurant/meshes",
            SCENES_ART / "kits" / "Restaurant_Kit_Index.tscn",
            30,
        ),
        "interior": write_kit_index_scene(
            "Interior_Kit_Index",
            ASSETS / "environment/interior/house_interior/meshes",
            SCENES_ART / "kits" / "Interior_Kit_Index.tscn",
            30,
        ),
    }

    print("Test scenes...")
    write_blockout_scene(
        SCENES_ART / "rooms" / "Apartment_Blockout_Finalized.tscn",
        "Apartment_Blockout_Finalized",
        (0.88, 0.85, 0.8),
        [
            ("Wall_N", 0, 0, -7.5, 16, 3, 0.3),
            ("Wall_S", 0, 0, 7.5, 16, 3, 0.3),
            ("Wall_W", -7.5, 0, 0, 0.3, 3, 16),
            ("Wall_E", 7.5, 0, 0, 0.3, 3, 16),
            ("Kitchen_Counter", -4, 0, -3, 3, 0.9, 0.8),
            ("Sofa", 2, 0, 1, 2.4, 0.8, 1.0),
            ("Bed", 4, 0, -4, 2.0, 0.5, 1.6),
            ("Table", 0, 0, 0, 1.2, 0.7, 0.8),
            ("Bath_Zone", -5, 0, 4, 2.5, 2.2, 2.5),
            ("Door_Interact", 0, 0, 7.2, 1.0, 2.1, 0.2),
            ("Wardrobe", 6, 0, -1, 1.2, 2.0, 0.6),
        ],
    )
    write_blockout_scene(
        SCENES_ART / "city" / "City_Street_Slice.tscn",
        "City_Street_Slice",
        (0.18, 0.18, 0.2),
        [
            ("Road", 0, 0, 0, 16, 0.15, 6),
            ("Sidewalk_N", 0, 0, -4.5, 16, 0.25, 2),
            ("Sidewalk_S", 0, 0, 4.5, 16, 0.25, 2),
            ("Facade_Home", -5, 0, -6.5, 5, 6, 1.2),
            ("Facade_Restaurant", 2, 0, -6.5, 5, 5, 1.2),
            ("Facade_ShopA", 7, 0, -6.5, 3.5, 4.5, 1.0),
            ("Facade_ShopB", -9, 0, -6.5, 3, 4, 1.0),
            ("Prop_Lamp", -2, 0, -3.5, 0.3, 3.5, 0.3),
            ("Prop_Bench", 4, 0, 3.5, 1.5, 0.5, 0.5),
        ],
    )
    write_blockout_scene(
        SCENES_ART / "restaurant" / "Sushi_Date_Restaurant.tscn",
        "Sushi_Date_Restaurant",
        (0.45, 0.32, 0.25),
        [
            ("Wall_N", 0, 0, -7, 14, 3.5, 0.3),
            ("Wall_S", 0, 0, 7, 14, 3.5, 0.3),
            ("Wall_W", -7, 0, 0, 0.3, 3.5, 14),
            ("Wall_E", 7, 0, 0, 0.3, 3.5, 14),
            ("Bar", -4, 0, -3, 5, 1.1, 1.2),
            ("Table_1", -1, 0, 1, 1.2, 0.75, 1.2),
            ("Table_2", 2, 0, 1, 1.2, 0.75, 1.2),
            ("Table_3", -1, 0, 4, 1.2, 0.75, 1.2),
            ("Table_4", 2, 0, 4, 1.2, 0.75, 1.2),
            ("Table_5", 4.5, 0, 2.5, 1.2, 0.75, 1.2),
            ("Kitchen", 5, 0, -4, 3.5, 2.2, 3),
            ("Entrance", 0, 0, 6.7, 2, 2.4, 0.3),
            ("DateSeat", 2, 0, 1.8, 0.5, 0.9, 0.5),
        ],
    )
    write_blockout_scene(
        SCENES_ART / "lab" / "Clone_Lab_Base.tscn",
        "Clone_Lab_Base",
        (0.85, 0.88, 0.92),
        [
            ("Wall_N", 0, 0, -6, 12, 3.2, 0.25),
            ("Wall_S", 0, 0, 6, 12, 3.2, 0.25),
            ("Wall_W", -6, 0, 0, 0.25, 3.2, 12),
            ("Wall_E", 6, 0, 0, 0.25, 3.2, 12),
            ("Terminal", -3, 0, -3, 1.2, 1.6, 0.6),
            ("Tube_A", 1, 0, -2, 1.0, 2.6, 1.0),
            ("Tube_B", 3, 0, -2, 1.0, 2.6, 1.0),
            ("Crate_Stack", -4, 0, 2, 1.5, 1.2, 1.5),
            ("Desk", 0, 0, 2, 2.0, 0.8, 1.0),
            ("InspectPad", 2, 0, 3, 2.0, 0.15, 2.0),
            ("Locker", 5, 0, 0, 0.8, 2.2, 0.6),
        ],
    )
    write_blockout_scene(
        SCENES_ART / "factory" / "Date_Factory_Base.tscn",
        "Date_Factory_Base",
        (0.25, 0.26, 0.28),
        [
            ("Wall_N", 0, 0, -7, 16, 4, 0.3),
            ("Wall_S", 0, 0, 7, 16, 4, 0.3),
            ("Wall_W", -8, 0, 0, 0.3, 4, 14),
            ("Wall_E", 8, 0, 0, 0.3, 4, 14),
            ("Conveyor", 0, 0, 0, 8, 0.6, 1.2),
            ("Machine_A", -4, 0, -2, 2.2, 2.0, 2.0),
            ("Machine_B", 4, 0, -2, 2.2, 2.0, 2.0),
            ("Machine_C", 0, 0, -4, 2.5, 1.8, 2.0),
            ("Pipe_Run", 6, 1.5, 0, 0.4, 0.4, 8),
            ("Container_A", -6, 0, 3, 1.5, 1.5, 1.5),
            ("Container_B", -4, 0, 3, 1.5, 1.5, 1.5),
            ("GiftPrep", 3, 0, 3.5, 2.5, 1.2, 1.5),
        ],
    )
    write_character_testbed()
    write_mesh_bridge_notes()

    LOG["test_scenes"] = [
        "res://scenes/art/rooms/Apartment_Blockout_Finalized.tscn",
        "res://scenes/art/city/City_Street_Slice.tscn",
        "res://scenes/art/restaurant/Sushi_Date_Restaurant.tscn",
        "res://scenes/art/lab/Clone_Lab_Base.tscn",
        "res://scenes/art/factory/Date_Factory_Base.tscn",
        "res://scenes/art/testbeds/Character_Testbed.tscn",
    ]
    LOG["finished"] = datetime.now(timezone.utc).isoformat()
    LOG["copied_mb"] = round(LOG["bytes"] / (1024 * 1024), 2)

    (DOCS / "import_pipeline_state.json").write_text(json.dumps(LOG, indent=2), encoding="utf-8")
    print(json.dumps({"copied_files": LOG["copied_files"], "mb": LOG["copied_mb"], "packs": list(LOG["packs"].keys())}, indent=2))


if __name__ == "__main__":
    main()
