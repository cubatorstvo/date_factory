"""Diagnose Proxy A-pose mesh vs UAL T-rest armature mismatch."""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

from proxy_paths import add_common_args, ensure_dir, fail, log, parse_argv_after_double_dash  # noqa: E402


def _set_engine(scene: bpy.types.Scene) -> None:
    engines = {item.identifier for item in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items}
    if "BLENDER_EEVEE_NEXT" in engines:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    elif "BLENDER_EEVEE" in engines:
        scene.render.engine = "BLENDER_EEVEE"
    else:
        scene.render.engine = "BLENDER_WORKBENCH"


def _find_master() -> bpy.types.Object:
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE" and "UAL_Master" in obj.name:
            return obj
    arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    if not arms:
        fail("No armature in blend")
    return arms[0]


def _clear_anim(arm: bpy.types.Object) -> None:
    if arm.animation_data:
        arm.animation_data.action = None
        if hasattr(arm.animation_data, "action_slot"):
            try:
                arm.animation_data.action_slot = None
            except Exception:  # noqa: BLE001
                pass
        for tr in arm.animation_data.nla_tracks:
            tr.mute = True
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.pose.transforms_clear()
    bpy.ops.object.mode_set(mode="OBJECT")
    arm.data.pose_position = "REST"
    bpy.context.view_layer.update()


def _bone_world_dir(arm: bpy.types.Object, name: str) -> Vector | None:
    b = arm.data.bones.get(name)
    if b is None:
        return None
    h = arm.matrix_world @ b.head_local
    t = arm.matrix_world @ b.tail_local
    d = t - h
    return d.normalized() if d.length > 1e-8 else None


def _mesh_arm_dir(mesh: bpy.types.Object, side: str) -> Vector | None:
    """Approx direction shoulder→hand tip from Proxy body verts."""
    mw = mesh.matrix_world
    sign = 1.0 if side == "l" else -1.0
    tips: list[Vector] = []
    shoulders: list[Vector] = []
    for v in mesh.data.vertices:
        w = mw @ v.co
        if w.x * sign < 0.12:
            continue
        if 1.15 < w.z < 1.55 and abs(w.x) > 0.35:
            tips.append(w)
        if 1.25 < w.z < 1.45 and 0.12 < abs(w.x) < 0.30:
            shoulders.append(w)
    if not tips or not shoulders:
        return None
    tip = max(tips, key=lambda p: abs(p.x))
    sh = sum(shoulders, Vector()) / len(shoulders)
    d = tip - sh
    return d.normalized() if d.length > 1e-8 else None


def _angle_deg(a: Vector | None, b: Vector | None) -> float | None:
    if a is None or b is None:
        return None
    return math.degrees(a.angle(b))


def _camera_front(center: Vector, height: float) -> None:
    cam = bpy.data.objects.get("DIAG_Cam")
    if cam is None:
        data = bpy.data.cameras.new("DIAG_Cam")
        cam = bpy.data.objects.new("DIAG_Cam", data)
        bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    dist = max(height * 2.4, 3.2)
    cam.location = (center.x, center.y - dist, center.z)
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = 50.0


def main() -> None:
    parser = argparse.ArgumentParser()
    add_common_args(parser)
    parser.add_argument("--blend", type=Path, default=None)
    args = parser.parse_args(parse_argv_after_double_dash())
    out = ensure_dir(args.output)
    diag = ensure_dir(out / "trest_fix")
    blend = args.blend or (out / "ProxyGirl_POC_Working.blend")
    if not blend.is_file():
        fail(f"Missing working blend: {blend}")

    bpy.ops.wm.open_mainfile(filepath=str(blend))
    arm = _find_master()
    _clear_anim(arm)
    arm.show_in_front = True
    arm.data.display_type = "OCTAHEDRAL"
    if hasattr(arm, "show_names"):
        arm.show_names = False

    body = bpy.data.objects.get("ProxyBody")
    if body is None:
        fail("ProxyBody missing")

    report = {
        "blend": str(blend),
        "armature": arm.name,
        "pose_position": arm.data.pose_position,
        "active_action": arm.animation_data.action.name if arm.animation_data and arm.animation_data.action else None,
        "bones": {},
        "mesh_arm_dirs": {},
        "mismatch_deg": {},
    }
    for side, bone in (("l", "upperarm_l"), ("r", "upperarm_r")):
        bd = _bone_world_dir(arm, bone)
        md = _mesh_arm_dir(body, side)
        report["bones"][bone] = [round(x, 4) for x in bd] if bd else None
        report["mesh_arm_dirs"][side] = [round(x, 4) for x in md] if md else None
        ang = _angle_deg(bd, md)
        report["mismatch_deg"][side] = None if ang is None else round(ang, 2)

    # Horizontal bone vs downward mesh => large angle (T vs A)
    report["verdict"] = "FAIL_A_MESH_ON_T_REST"
    if report["mismatch_deg"].get("l") is not None and report["mismatch_deg"]["l"] > 20:
        report["notes"] = "Upperarm bones near horizontal (T-rest); Proxy mesh arms angled down (A-pose)."
    else:
        report["notes"] = "Angles closer than expected; still verify visually."

    (diag / "before_rest_diagnosis.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    log(f"Diagnosis: {report}")

    _set_engine(bpy.context.scene)
    sc = bpy.context.scene
    sc.render.resolution_x = 1280
    sc.render.resolution_y = 720
    if sc.world is None:
        sc.world = bpy.data.worlds.new("DIAG_World")
    sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.08, 0.09, 0.11, 1.0)
    if not bpy.data.objects.get("DIAG_Light"):
        light = bpy.data.lights.new("DIAG_Light", type="AREA")
        light.energy = 900
        light.size = 4.0
        lob = bpy.data.objects.new("DIAG_Light", light)
        bpy.context.collection.objects.link(lob)
        lob.location = (2.0, -2.5, 3.0)

    # Ensure Proxy meshes visible
    for n in ("ProxyBody", "ProxyHair", "ProxyTop", "ProxyBottom", "ProxyShoes"):
        obj = bpy.data.objects.get(n)
        if obj:
            obj.hide_render = False
            obj.hide_viewport = False
            obj.hide_set(False)

    # Overlay armature
    arm.hide_render = False
    arm.hide_viewport = False

    # Approximate bounds
    pts: list[Vector] = []
    for n in ("ProxyBody", "ProxyTop", "ProxyBottom", "ProxyShoes", "ProxyHair"):
        obj = bpy.data.objects.get(n)
        if obj is None or obj.type != "MESH":
            continue
        for c in obj.bound_box:
            pts.append(obj.matrix_world @ Vector(c))
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    center = (mn + mx) * 0.5
    _camera_front(center, max((mx - mn).z, 1.5))

    path = diag / "before_rest_pose_front.png"
    sc.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    log(f"Wrote {path}")
    log("Diagnose complete")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        fail(f"Diagnose error: {exc}")
