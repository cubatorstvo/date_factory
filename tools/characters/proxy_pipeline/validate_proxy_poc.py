"""Validate Proxy POC working blend / GLB against critical deformation checks."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

import bpy  # noqa: E402

from proxy_paths import (  # noqa: E402
    UAL_CLIP_NAMES,
    add_common_args,
    ensure_dir,
    fail,
    log,
    parse_argv_after_double_dash,
    write_json,
)


def _armature() -> bpy.types.Object:
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE" and "UAL_Master" in obj.name or obj.type == "ARMATURE":
            if obj.type == "ARMATURE":
                return obj
    fail("Armature missing in validation scene")


def main() -> None:
    parser = argparse.ArgumentParser()
    add_common_args(parser)
    parser.add_argument("--blend", type=Path, default=None)
    parser.add_argument("--glb", type=Path, default=None)
    args = parser.parse_args(parse_argv_after_double_dash())
    out = ensure_dir(args.output)
    blend = args.blend or (out / "ProxyGirl_POC_Working.blend")
    glb = args.glb or (out / "GirlProxyPOC.glb")

    report = {"ok": True, "errors": [], "warnings": [], "checks": {}}

    if not blend.is_file():
        fail(f"Working blend missing: {blend}")
    bpy.ops.wm.open_mainfile(filepath=str(blend))

    arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    report["checks"]["armature_count"] = len(arms)
    if len(arms) != 1:
        # allow donor leftovers? Prefer 1
        report["warnings"].append(f"Expected 1 armature, found {len(arms)}: {[a.name for a in arms]}")

    required_meshes = ["ProxyBody", "ProxyHair", "ProxyTop", "ProxyBottom", "ProxyShoes"]
    for name in required_meshes:
        obj = bpy.data.objects.get(name)
        if obj is None:
            report["errors"].append(f"Missing mesh {name}")
            report["ok"] = False
            continue
        if not obj.vertex_groups and name != "ProxyHair":
            report["errors"].append(f"{name} has no vertex groups")
            report["ok"] = False
        arm_mods = [m for m in obj.modifiers if m.type == "ARMATURE"]
        if name != "ProxyHair" and not arm_mods:
            report["errors"].append(f"{name} missing Armature modifier")
            report["ok"] = False

    # Reopen exported GLB in clean scene
    if glb.is_file():
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(glb))
        arms2 = [o for o in bpy.data.objects if o.type == "ARMATURE"]
        meshes2 = [o for o in bpy.data.objects if o.type == "MESH"]
        report["checks"]["glb_armatures"] = len(arms2)
        report["checks"]["glb_meshes"] = len(meshes2)
        report["checks"]["glb_mesh_names"] = [m.name for m in meshes2]
        if len(arms2) != 1:
            report["errors"].append(f"GLB armature count {len(arms2)}")
            report["ok"] = False
        if len(meshes2) < 4:
            report["errors"].append(f"GLB mesh count too low: {len(meshes2)}")
            report["ok"] = False
    else:
        report["errors"].append(f"GLB missing: {glb}")
        report["ok"] = False

    write_json(out / "validate_report.json", report)
    (out / "VALIDATE_SUMMARY.md").write_text(
        "# Validate summary\n\n"
        + f"- ok: **{report['ok']}**\n"
        + "\n".join(f"- ERROR: {e}" for e in report["errors"])
        + "\n"
        + "\n".join(f"- WARN: {w}" for w in report["warnings"])
        + "\n",
        encoding="utf-8",
    )
    log(json.dumps(report, indent=2))
    if not report["ok"]:
        fail("Validation failed")
    log("Validation passed")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        fail(f"Unhandled validate error: {exc}")
