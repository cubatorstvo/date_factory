"""Debug: why A-rest → T deform fails. Run inside Blender on a mid-state or rebuilds a mini case."""
from __future__ import annotations

import sys
from pathlib import Path

_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

import bpy
from mathutils import Matrix, Vector

from proxy_paths import ensure_dir, log, parse_argv_after_double_dash


def main() -> None:
    out = Path(r"C:\Users\User\Downloads\date_factory_proxy_work")
    blend = out / "DEBUG_trest_fail.blend"
    # Prefer a dedicated mid-state if present
    mid = out / "DEBUG_pre_bake.blend"
    path = mid if mid.is_file() else blend
    if not path.is_file():
        log(f"No debug blend at {path}")
        raise SystemExit(1)
    bpy.ops.wm.open_mainfile(filepath=str(path))

    transfer = bpy.data.objects.get("UAL_TransferArmature")
    master = bpy.data.objects.get("UAL_MasterArmature")
    body = bpy.data.objects.get("ProxyBody")
    log(f"transfer={transfer} master={master} body={body}")
    if not body:
        raise SystemExit(2)

    # Print arm bone rests
    for arm, label in ((transfer, "transfer"), (master, "master")):
        if arm is None:
            continue
        for name in ("clavicle_l", "upperarm_l", "lowerarm_l"):
            b = arm.data.bones.get(name)
            if not b:
                continue
            h = arm.matrix_world @ b.head_local
            t = arm.matrix_world @ b.tail_local
            d = (t - h).normalized()
            log(f"{label}.{name} head={tuple(round(x,3) for x in h)} dir={tuple(round(x,3) for x in d)}")

    # Find a tip-ish vertex (high |x|, mid z)
    mw = body.matrix_world
    tip_i, tip_x = -1, -1.0
    for i, v in enumerate(body.data.vertices):
        w = mw @ v.co
        if 1.1 < w.z < 1.45 and w.x > tip_x:
            tip_x = w.x
            tip_i = i
    log(f"tip vert {tip_i} world={tuple(round(x,3) for x in (mw @ body.data.vertices[tip_i].co))}")
    # weights on tip
    for g in body.data.vertices[tip_i].groups:
        vg = body.vertex_groups[g.group]
        log(f"  tip weight {vg.name}={g.weight:.3f}")

    if transfer is None or master is None:
        raise SystemExit(3)

    # Compare deform for upperarm_l
    tb = transfer.data.bones["upperarm_l"]
    mb = master.data.bones["upperarm_l"]
    rest = transfer.matrix_world @ tb.matrix_local
    target = master.matrix_world @ mb.matrix_local
    log(f"rest.translation={tuple(round(x,3) for x in rest.translation)}")
    log(f"target.translation={tuple(round(x,3) for x in target.translation)}")
    delta = target @ rest.inverted()
    log(f"delta.translation={tuple(round(x,3) for x in delta.translation)}")
    log(f"delta.to_euler={tuple(round(x,3) for x in delta.to_euler('XYZ'))}")

    # Test: does armature modifier move tip if we rotate upperarm?
    for mod in body.modifiers:
        if mod.type == "ARMATURE":
            log(f"arm_mod object={mod.object} vgroups={mod.use_vertex_groups} viewport={mod.show_viewport}")
    bpy.context.view_layer.objects.active = transfer
    transfer.data.pose_position = "POSE"
    bpy.ops.object.mode_set(mode="POSE")
    pb = transfer.pose.bones.get("upperarm_l")
    if pb:
        pb.rotation_mode = "XYZ"
        before = None
        bpy.context.view_layer.update()
        deps = bpy.context.evaluated_depsgraph_get()
        ev = body.evaluated_get(deps)
        m = ev.to_mesh()
        before = ev.matrix_world @ m.vertices[tip_i].co
        ev.to_mesh_clear()
        pb.rotation_euler[2] += 0.7
        bpy.context.view_layer.update()
        deps = bpy.context.evaluated_depsgraph_get()
        ev = body.evaluated_get(deps)
        m = ev.to_mesh()
        after = ev.matrix_world @ m.vertices[tip_i].co
        ev.to_mesh_clear()
        log(f"rotate upperarm_l Z+0.7 tip before={tuple(round(x,3) for x in before)} after={tuple(round(x,3) for x in after)} delta={(after-before).length:.4f}")
    bpy.ops.object.mode_set(mode="OBJECT")


if __name__ == "__main__":
    main()
