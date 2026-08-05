"""Render POC animation proof frames from the working blend."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

from proxy_paths import (  # noqa: E402
    add_common_args,
    ensure_dir,
    fail,
    log,
    parse_argv_after_double_dash,
)


FRAMES = [
    ("01_rest_front.png", None, "FRONT", 1, False),
    ("02_rest_side.png", None, "SIDE", 1, False),
    ("03_walk_side.png", "Walk_Loop", "SIDE", 12, False),
    ("04_walk_front.png", "Walk_Loop", "FRONT", 12, False),
    ("05_sit_enter_side.png", "Sitting_Enter", "SIDE", 10, True),
    ("06_sit_idle_side.png", "Sitting_Idle_Loop", "SIDE", 8, True),
    ("07_seated_gesture_front.png", "Sitting_Talking_Loop", "FRONT", 10, True),
    ("08_sit_exit_side.png", "Sitting_Exit", "SIDE", 10, True),
]


def _set_engine(scene: bpy.types.Scene) -> None:
    engines = {item.identifier for item in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items}
    if "BLENDER_EEVEE_NEXT" in engines:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    elif "BLENDER_EEVEE" in engines:
        scene.render.engine = "BLENDER_EEVEE"
    else:
        scene.render.engine = "BLENDER_WORKBENCH"


def _eval_bbox(objs: list[bpy.types.Object]) -> tuple[Vector, Vector, Vector]:
    deps = bpy.context.evaluated_depsgraph_get()
    pts: list[Vector] = []
    for obj in objs:
        if obj is None or obj.type != "MESH":
            continue
        ev = obj.evaluated_get(deps)
        mesh = ev.to_mesh()
        try:
            for v in mesh.vertices:
                pts.append(ev.matrix_world @ v.co)
        finally:
            ev.to_mesh_clear()
    if not pts:
        return Vector((0, 0, 0)), Vector((1, 1, 1.8)), Vector((0, 0, 0.9))
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return mn, mx, (mn + mx) * 0.5


def _ensure_chair(visible: bool, seat_anchor: Vector | None) -> None:
    # Always recreate so leftover scale/location from prior frames cannot poison proofs.
    for name in ("TechChair", "TechChairBack"):
        obj = bpy.data.objects.get(name)
        if obj is not None:
            bpy.data.objects.remove(obj, do_unlink=True)

    if not visible or seat_anchor is None:
        return

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.0))
    seat = bpy.context.active_object
    seat.name = "TechChair"
    seat.dimensions = (0.56, 0.48, 0.04)
    bpy.ops.object.transform_apply(scale=True)
    mat = bpy.data.materials.get("MAT_TechChair")
    if mat is None:
        mat = bpy.data.materials.new("MAT_TechChair")
        mat.diffuse_color = (0.40, 0.41, 0.43, 1.0)
    if seat.data.materials:
        seat.data.materials[0] = mat
    else:
        seat.data.materials.append(mat)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.0))
    back = bpy.context.active_object
    back.name = "TechChairBack"
    back.dimensions = (0.56, 0.04, 0.40)
    bpy.ops.object.transform_apply(scale=True)
    back.data.materials.append(mat)

    # Under the hips: Quaternius faces -Y, so slightly +Y is behind the character.
    seat.location = Vector((seat_anchor.x, seat_anchor.y + 0.02, seat_anchor.z - 0.18))
    back.location = Vector((seat_anchor.x, seat.location.y + 0.24, seat.location.z + 0.30))
    for obj in (seat, back):
        obj.hide_render = False
        obj.hide_viewport = False
        obj.hide_set(False)


def _camera(view: str, mn: Vector, mx: Vector, center: Vector) -> bpy.types.Object:
    cam = bpy.data.objects.get("POC_Cam")
    if cam is None:
        data = bpy.data.cameras.new("POC_Cam")
        data.clip_start = 0.05
        data.clip_end = 200.0
        cam = bpy.data.objects.new("POC_Cam", data)
        bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    size = mx - mn
    height = max(size.z, 0.5)
    width = max(size.x, size.y, 0.5)
    dist = max(height * 2.6, width * 2.8, 3.5)
    # Pad framing so feet + head clear edges
    target = Vector((center.x, center.y, mn.z + height * 0.52))
    if view == "FRONT":
        cam.location = (target.x, target.y - dist, target.z)
    else:
        cam.location = (target.x + dist, target.y, target.z)
    direction = target - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    cam.data.type = "PERSP"
    cam.data.lens = 50.0
    return cam


def _play(arm: bpy.types.Object, action_name: str | None, frame: int) -> None:
    if not arm.animation_data:
        arm.animation_data_create()
    ad = arm.animation_data
    for tr in ad.nla_tracks:
        tr.mute = True

    # Always reset pose before applying a clip so leftover UAL import pose cannot leak.
    bpy.context.view_layer.objects.active = arm
    try:
        bpy.ops.object.mode_set(mode="POSE")
        bpy.ops.pose.select_all(action="SELECT")
        bpy.ops.pose.transforms_clear()
        bpy.ops.object.mode_set(mode="OBJECT")
    except Exception as exc:  # noqa: BLE001
        log(f"WARNING pose clear failed: {exc}")
        try:
            bpy.ops.object.mode_set(mode="OBJECT")
        except Exception:  # noqa: BLE001
            pass

    if action_name:
        match = None
        for tr in ad.nla_tracks:
            if tr.name == action_name or action_name.lower() in tr.name.lower():
                match = tr
                break
        if match is None:
            for tr in ad.nla_tracks:
                for strip in tr.strips:
                    if strip.action and action_name.lower() in strip.action.name.lower():
                        match = tr
                        break
                if match:
                    break
        if match is None:
            log(f"WARNING missing action/track {action_name}; available={[t.name for t in ad.nla_tracks][:20]}")
            ad.action = None
        else:
            match.mute = False
            if match.strips:
                strip = match.strips[0]
                ad.action = strip.action
                if hasattr(ad, "action_slot") and hasattr(strip, "action_slot"):
                    try:
                        ad.action_slot = strip.action_slot
                    except Exception:  # noqa: BLE001
                        pass
    else:
        ad.action = None
        if hasattr(ad, "action_slot"):
            try:
                ad.action_slot = None
            except Exception:  # noqa: BLE001
                pass
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()


def _pelvis_world(arm: bpy.types.Object) -> Vector | None:
    pb = arm.pose.bones.get("pelvis")
    if pb is None:
        return None
    return arm.matrix_world @ pb.head


def _sit_seat_target(arm: bpy.types.Object) -> Vector | None:
    """Average of thigh heads + pelvis — more stable seat anchor than pelvis alone."""
    pts: list[Vector] = []
    for name in ("pelvis", "thigh_l", "thigh_r"):
        pb = arm.pose.bones.get(name)
        if pb is not None:
            pts.append(arm.matrix_world @ pb.head)
    if not pts:
        return None
    acc = Vector((0, 0, 0))
    for p in pts:
        acc += p
    return acc / len(pts)


def _render_compare_overlays(out: Path, arm: bpy.types.Object) -> None:
    """Donor vs Proxy front/side overlays for fit QA."""
    donor = bpy.data.objects.get("DonorBody_PACK021")
    body = bpy.data.objects.get("ProxyBody")
    if donor is None or body is None:
        return
    # Rest pose
    _play(arm, None, 1)
    donor.hide_render = False
    donor.hide_viewport = False
    donor.hide_set(False)
    # Semi-transparent donor
    if donor.data.materials:
        mat = donor.data.materials[0]
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf and "Alpha" in bsdf.inputs:
            bsdf.inputs["Alpha"].default_value = 0.35
        mat.blend_method = "BLEND" if hasattr(mat, "blend_method") else mat.blend_method

    pieces = [body, bpy.data.objects.get("ProxyHair"), bpy.data.objects.get("ProxyTop"),
              bpy.data.objects.get("ProxyBottom"), bpy.data.objects.get("ProxyShoes"), donor]
    mn, mx, center = _eval_bbox([o for o in pieces if o])
    compare_dir = ensure_dir(out / "blender_renders" / "compare")
    for name, view in (("donor_proxy_front.png", "FRONT"), ("donor_proxy_side.png", "SIDE")):
        _camera(view, mn, mx, center)
        path = compare_dir / name
        bpy.context.scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        log(f"Rendered compare {path}")
    donor.hide_render = True
    donor.hide_viewport = True
    donor.hide_set(True)


def main() -> None:
    parser = argparse.ArgumentParser()
    add_common_args(parser)
    parser.add_argument("--blend", type=Path, default=None)
    args = parser.parse_args(parse_argv_after_double_dash())
    out = ensure_dir(args.output)
    renders = ensure_dir(out / "blender_renders")
    blend = args.blend or (out / "ProxyGirl_POC_Working.blend")
    if not blend.is_file():
        fail(f"Missing working blend: {blend}")
    bpy.ops.wm.open_mainfile(filepath=str(blend))
    _set_engine(bpy.context.scene)
    bpy.context.scene.render.resolution_x = 1280
    bpy.context.scene.render.resolution_y = 720
    bpy.context.scene.render.film_transparent = False
    bpy.context.scene.world = bpy.data.worlds.new("POC_World") if bpy.context.scene.world is None else bpy.context.scene.world
    if bpy.context.scene.world:
        bpy.context.scene.world.use_nodes = True
        bg = bpy.context.scene.world.node_tree.nodes.get("Background")
        if bg:
            bg.inputs[0].default_value = (0.08, 0.09, 0.11, 1.0)

    if not bpy.data.objects.get("POC_Light"):
        light = bpy.data.lights.new("POC_Light", type="AREA")
        light.energy = 800
        light.size = 3.0
        lob = bpy.data.objects.new("POC_Light", light)
        bpy.context.collection.objects.link(lob)
        lob.location = (2.5, -2.5, 3.5)
    # Fill light
    if not bpy.data.objects.get("POC_Fill"):
        fill = bpy.data.lights.new("POC_Fill", type="AREA")
        fill.energy = 250
        fill.size = 4.0
        fob = bpy.data.objects.new("POC_Fill", fill)
        bpy.context.collection.objects.link(fob)
        fob.location = (-2.0, 1.5, 2.0)

    arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    if not arms:
        fail("No armature for render")
    arm = next((a for a in arms if "UAL_Master" in a.name), arms[0])
    proxy_meshes = [
        bpy.data.objects.get(n)
        for n in ("ProxyBody", "ProxyHair", "ProxyTop", "ProxyBottom", "ProxyShoes")
    ]

    _render_compare_overlays(out, arm)

    for filename, action, view, frame, need_chair in FRAMES:
        _play(arm, action, frame)
        anchor = _sit_seat_target(arm) if need_chair else None
        _ensure_chair(need_chair, anchor)
        mn, mx, center = _eval_bbox([o for o in proxy_meshes if o])
        if need_chair:
            chair = bpy.data.objects.get("TechChair")
            back = bpy.data.objects.get("TechChairBack")
            mn2, mx2, _ = _eval_bbox([o for o in (chair, back) if o and not o.hide_render])
            mn = Vector((min(mn.x, mn2.x), min(mn.y, mn2.y), min(mn.z, mn2.z)))
            mx = Vector((max(mx.x, mx2.x), max(mx.y, mx2.y), max(mx.z, mx2.z)))
            center = (mn + mx) * 0.5
        _camera(view, mn, mx, center)
        path = renders / filename
        bpy.context.scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        log(f"Rendered {path}")
    log("Render complete")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        fail(f"Unhandled render error: {exc}")
