"""
Fix Proxy POC: A-pose skin → deform to T → bake geometry → bind clean T-rest UAL master.

Does NOT alter UAL_MasterArmature rest pose / hierarchy / bone names.
"""
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
from mathutils import Matrix, Quaternion, Vector  # noqa: E402

from poc_selection import SELECTION  # noqa: E402
from proxy_paths import (  # noqa: E402
    add_common_args,
    ensure_dir,
    fail,
    log,
    parse_argv_after_double_dash,
    require_file,
    write_json,
)


PROXY_MESHES = ("ProxyBody", "ProxyTop", "ProxyBottom", "ProxyShoes", "ProxyHair")
BAKE_MESHES = ("ProxyBody", "ProxyTop", "ProxyBottom", "ProxyShoes")


def _clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _bbox(obj: bpy.types.Object) -> tuple[Vector, Vector, Vector]:
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    mn = Vector((min(c.x for c in corners), min(c.y for c in corners), min(c.z for c in corners)))
    mx = Vector((max(c.x for c in corners), max(c.y for c in corners), max(c.z for c in corners)))
    return mn, mx, (mn + mx) * 0.5


def _apply_object_transforms(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def _clear_shape_keys(obj: bpy.types.Object) -> None:
    if obj.type != "MESH" or obj.data.shape_keys is None:
        return
    obj.shape_key_clear()
    log(f"Cleared shape keys on {obj.name}")


def _apply_constructive_modifiers(obj: bpy.types.Object) -> None:
    if obj.type != "MESH":
        return
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    for mod in list(obj.modifiers):
        if mod.type == "MIRROR":
            try:
                bpy.ops.object.modifier_apply(modifier=mod.name)
            except Exception as exc:  # noqa: BLE001
                log(f"WARNING mirror apply {obj.name}: {exc}")
                obj.modifiers.remove(mod)
        elif mod.type == "SOLIDIFY":
            obj.modifiers.remove(mod)
        elif mod.type in {"SUBSURF", "BEVEL", "TRIANGULATE", "WEIGHTED_NORMAL"}:
            try:
                bpy.ops.object.modifier_apply(modifier=mod.name)
            except Exception as exc:  # noqa: BLE001
                log(f"WARNING {mod.type} apply {obj.name}: {exc}")
                obj.modifiers.remove(mod)


def _bone_world_head(arm: bpy.types.Object, name: str) -> Vector | None:
    bone = arm.data.bones.get(name)
    if bone is None:
        return None
    return arm.matrix_world @ bone.head_local


def _bone_world_tail(arm: bpy.types.Object, name: str) -> Vector | None:
    bone = arm.data.bones.get(name)
    if bone is None:
        return None
    return arm.matrix_world @ bone.tail_local


def _find_armature() -> bpy.types.Object:
    arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    if not arms:
        fail("No Armature after donor import")
    for preferred in ("CharacterArmature", "Armature", "Skeleton"):
        for arm in arms:
            if preferred.lower() in arm.name.lower():
                return arm
    return arms[0]


def _find_donor_body(arm: bpy.types.Object) -> bpy.types.Object:
    meshes = [
        o
        for o in bpy.data.objects
        if o.type == "MESH" and (o.parent == arm or any(m.type == "ARMATURE" and m.object == arm for m in o.modifiers))
    ]
    if not meshes:
        meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    meshes.sort(key=lambda o: len(o.data.vertices), reverse=True)
    if not meshes:
        fail("Donor body not found")
    return meshes[0]


def _import_donor(donor_path: Path) -> tuple[bpy.types.Object, bpy.types.Object]:
    log(f"Import donor: {donor_path}")
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(donor_path))
    after = [o for o in bpy.data.objects if o not in before]
    arm = _find_armature()
    body = _find_donor_body(arm)
    body.name = "DonorBody_PACK021"
    arm.name = "UAL_MasterArmature"
    for obj in list(after):
        if obj in (arm, body):
            continue
        if obj.type == "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)
    # Ensure donor uses master armature
    for mod in list(body.modifiers):
        if mod.type == "ARMATURE":
            mod.object = arm
    body.parent = arm
    body.parent_type = "OBJECT"
    body.matrix_parent_inverse = arm.matrix_world.inverted()
    body.hide_render = True
    return arm, body


def _duplicate_transfer_armature(master: bpy.types.Object) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    master.select_set(True)
    bpy.context.view_layer.objects.active = master
    bpy.ops.object.duplicate(linked=False)
    transfer = bpy.context.active_object
    transfer.name = "UAL_TransferArmature"
    # Strip animation from transfer copy — pose only for geometry prep
    if transfer.animation_data:
        transfer.animation_data_clear()
    transfer.data.pose_position = "POSE"
    log("Created UAL_TransferArmature (temporary)")
    return transfer


def _append_proxy(proxy_blend: Path, names: list[str]) -> dict[str, bpy.types.Object]:
    with bpy.data.libraries.load(str(proxy_blend), link=False) as (data_from, data_to):
        available = set(data_from.objects)
        resolved = []
        lowered = {n.lower(): n for n in available}
        for n in names:
            if n in available:
                resolved.append(n)
            elif n.lower() in lowered:
                resolved.append(lowered[n.lower()])
            else:
                fail(f"Proxy object missing: {n}")
        data_to.objects = resolved
    linked: dict[str, bpy.types.Object] = {}
    for obj in data_to.objects:
        if obj is None:
            continue
        bpy.context.collection.objects.link(obj)
        linked[obj.name] = obj
    return linked


def _fit_proxy_set(pieces: dict[str, bpy.types.Object], donor: bpy.types.Object, arm: bpy.types.Object) -> None:
    for obj in pieces.values():
        _apply_constructive_modifiers(obj)
        _clear_shape_keys(obj)

    body = pieces["ProxyBody"]
    d_min, d_max, d_c = _bbox(donor)
    b_min, b_max, b_c = _bbox(body)
    d_size = d_max - d_min
    b_size = b_max - b_min
    scale = d_size.z / max(b_size.z, 1e-6)
    for obj in pieces.values():
        obj.scale = Vector(obj.scale) * scale
    bpy.context.view_layer.update()
    b_min, b_max, b_c = _bbox(body)
    delta = Vector((d_c.x - b_c.x, d_c.y - b_c.y, d_min.z - b_min.z))
    for obj in pieces.values():
        obj.location += delta
    bpy.context.view_layer.update()
    for obj in pieces.values():
        _apply_object_transforms(obj)

    # Mild clothes fit while still A-pose
    for key, offset, max_d in (
        ("ProxyTop", 0.014, 0.08),
        ("ProxyBottom", 0.022, 0.12),
        ("ProxyShoes", 0.008, 0.06),
    ):
        cloth = pieces[key]
        bpy.ops.object.select_all(action="DESELECT")
        cloth.select_set(True)
        bpy.context.view_layer.objects.active = cloth
        mod = cloth.modifiers.new(name="SW_FitBody", type="SHRINKWRAP")
        mod.target = body
        mod.wrap_method = "NEAREST_SURFACEPOINT"
        mod.wrap_mode = "ABOVE_SURFACE"
        mod.offset = offset
        if hasattr(mod, "use_max_distance"):
            mod.use_max_distance = True
            mod.max_distance = max_d
        try:
            bpy.ops.object.modifier_apply(modifier=mod.name)
        except Exception as exc:  # noqa: BLE001
            log(f"WARNING shrinkwrap {key}: {exc}")
            if mod.name in cloth.modifiers:
                cloth.modifiers.remove(mod)

    hair = pieces["ProxyHair"]
    head = _bone_world_head(arm, "Head")
    if head is not None:
        _hmin, _hmax, hc = _bbox(hair)
        hair.location += Vector((head.x - hc.x, head.y - hc.y, (head.z + 0.08) - hc.z))
        bpy.context.view_layer.update()
        _apply_object_transforms(hair)

    shoes = pieces["ProxyShoes"]
    s_min, s_max, s_c = _bbox(shoes)
    fl = _bone_world_head(arm, "foot_l")
    fr = _bone_world_head(arm, "foot_r")
    if fl and fr:
        mid = (fl + fr) * 0.5
        shoes.location += Vector((mid.x - s_c.x, mid.y - s_c.y, d_min.z - s_min.z))
        bpy.context.view_layer.update()
        _apply_object_transforms(shoes)
    log("Fitted Proxy set (kept authored A-pose volume)")


def _mesh_arm_joints(mesh: bpy.types.Object, side: str) -> tuple[Vector | None, Vector | None, Vector | None]:
    """Approximate shoulder / elbow / wrist world points from A-pose mesh."""
    mw = mesh.matrix_world
    sign = 1.0 if side == "l" else -1.0
    pts: list[Vector] = []
    for v in mesh.data.vertices:
        w = mw @ v.co
        if w.x * sign < 0.10:
            continue
        if w.z < 0.95 or w.z > 1.55:
            continue
        pts.append(w.copy())
    if len(pts) < 6:
        return None, None, None
    # shoulder = lowest |x| among high-Z; wrist = highest |x|
    shoulder = min(pts, key=lambda p: (abs(p.x), -p.z))
    wrist = max(pts, key=lambda p: abs(p.x))
    # elbow ≈ midpoint by distance along shoulder→wrist, prefer lower Z
    axis = wrist - shoulder
    if axis.length < 1e-4:
        return shoulder, None, wrist
    axis_n = axis.normalized()
    mid_target = shoulder + axis_n * (axis.length * 0.48)
    elbow = min(pts, key=lambda p: (p - mid_target).length + max(0.0, p.z - mid_target.z) * 0.15)
    return shoulder, elbow, wrist


def _aim_pose_bone_world(arm: bpy.types.Object, name: str, target_world: Vector) -> None:
    """Rotate pose bone so head→tail aims at target_world (rotation about head)."""
    pb = arm.pose.bones.get(name)
    if pb is None:
        return
    mw = arm.matrix_world
    head_w = mw @ pb.head
    cur = (mw @ pb.tail) - head_w
    if cur.length < 1e-8:
        return
    tgt = target_world - head_w
    if tgt.length < 1e-8:
        return
    q = cur.normalized().rotation_difference(tgt.normalized())
    R = q.to_matrix().to_4x4()
    T = Matrix.Translation(head_w)
    Mw = mw @ pb.matrix
    pb.matrix = mw.inverted() @ (T @ R @ T.inverted() @ Mw)


def _pose_transfer_to_proxy_a(transfer: bpy.types.Object, proxy_body: bpy.types.Object) -> None:
    """
    Pose transfer arms to match Proxy A-pose (shoulder→elbow→wrist).
    Does NOT apply as rest pose yet (caller may Apply Pose as Rest on TRANSFER only).
    """
    bpy.context.view_layer.objects.active = transfer
    transfer.data.pose_position = "POSE"
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.pose.transforms_clear()
    bpy.context.view_layer.update()

    for side in ("l", "r"):
        shoulder_m, elbow_m, wrist_m = _mesh_arm_joints(proxy_body, side)
        if elbow_m is None or wrist_m is None:
            log(f"WARNING: could not find mesh arm joints for {side}")
            continue
        # Mild clavicle toward elbow laterally
        clav = f"clavicle_{side}"
        ua = f"upperarm_{side}"
        la = f"lowerarm_{side}"
        _aim_pose_bone_world(transfer, ua, elbow_m)
        bpy.context.view_layer.update()
        _aim_pose_bone_world(transfer, la, wrist_m)
        bpy.context.view_layer.update()
        # Verify
        pb = transfer.pose.bones.get(ua)
        if pb:
            d = ((transfer.matrix_world @ pb.tail) - (transfer.matrix_world @ pb.head)).normalized()
            mesh_d = (elbow_m - (transfer.matrix_world @ pb.head)).normalized()
            ang = math.degrees(d.angle(mesh_d)) if d.length and mesh_d.length else 999
            log(f"A-pose aim {ua}: bone={tuple(round(x,3) for x in d)} mesh={tuple(round(x,3) for x in mesh_d)} err={ang:.1f}°")

    bpy.ops.object.mode_set(mode="OBJECT")
    log("Posed UAL_TransferArmature toward Proxy A-pose (aimed)")


def _apply_pose_as_rest_transfer_only(transfer: bpy.types.Object) -> None:
    """Make current A-pose the TRANSFER bind/rest. Never touch UAL_MasterArmature."""
    bpy.context.view_layer.objects.active = transfer
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.pose.armature_apply(selected=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    _clear_pose(transfer)
    transfer.data.pose_position = "REST"
    bpy.context.view_layer.update()
    log("Applied Pose as Rest on UAL_TransferArmature ONLY (A-rest bind)")


def _save_pose_quats(arm: bpy.types.Object) -> dict[str, Quaternion]:
    """Snapshot current pose rotations (as quaternions) before Apply Pose as Rest."""
    saved: dict[str, Quaternion] = {}
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
        q = pb.rotation_quaternion.copy().normalized()
        if abs(q.w) > 0.9999 and abs(q.x) < 1e-4 and abs(q.y) < 1e-4 and abs(q.z) < 1e-4:
            continue
        saved[pb.name] = q
    return saved


def _bone_world_dir(arm: bpy.types.Object, name: str) -> Vector | None:
    pb = arm.pose.bones.get(name)
    if pb is None:
        return None
    mw = arm.matrix_world
    head = mw @ pb.head
    tail = mw @ pb.tail
    d = tail - head
    if d.length < 1e-8:
        return None
    return d.normalized()


def _mesh_arm_dir(obj: bpy.types.Object, side: str) -> Vector | None:
    """Approx upper-arm direction from shoulder cluster to wrist cluster (evaluated mesh)."""
    depsgraph = bpy.context.evaluated_depsgraph_get()
    eval_obj = obj.evaluated_get(depsgraph)
    mesh = eval_obj.to_mesh()
    try:
        mw = eval_obj.matrix_world
        sign = 1.0 if side == "l" else -1.0
        shoulder = None
        wrist = None
        sh_x, wr_x = -1.0, -1.0
        for v in mesh.vertices:
            w = mw @ v.co
            if w.z < 1.05 or w.z > 1.55:
                continue
            if w.x * sign < 0.08:
                continue
            ax = abs(w.x)
            # near body = shoulder; far = wrist-ish
            if ax < 0.35:
                if ax > sh_x or shoulder is None:
                    # prefer higher Z near shoulder
                    if shoulder is None or w.z > shoulder.z - 0.05:
                        sh_x = ax
                        shoulder = w.copy()
            if ax > wr_x and w.z < 1.45:
                wr_x = ax
                wrist = w.copy()
        if shoulder is None or wrist is None:
            return None
        d = wrist - shoulder
        if d.length < 1e-4:
            return None
        return d.normalized()
    finally:
        eval_obj.to_mesh_clear()


def _pose_transfer_toward_master_t_via_inverse(
    transfer: bpy.types.Object,
    saved_a_quats: dict[str, Quaternion],
) -> None:
    """After A-rest apply, pose with inverse of the A local quats to recover T visually."""
    bpy.context.view_layer.objects.active = transfer
    transfer.data.pose_position = "POSE"
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.pose.transforms_clear()
    for name, q in saved_a_quats.items():
        pb = transfer.pose.bones.get(name)
        if pb is None:
            continue
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = q.inverted().normalized()
    bpy.context.view_layer.update()
    bpy.ops.object.mode_set(mode="OBJECT")
    for name in ("upperarm_l", "upperarm_r"):
        d = _bone_world_dir(transfer, name)
        if d is not None:
            log(f"Inverse-T check {name} dir=({d.x:.3f},{d.y:.3f},{d.z:.3f})")
    log(f"Posed transfer A-rest → T via inverse of {len(saved_a_quats)} bones")


def _pose_transfer_toward_master_t(transfer: bpy.types.Object, master: bpy.types.Object) -> None:
    """
    After transfer has A-rest, pose every bone so its armature-space matrix matches
    the master's T-rest bone matrix. Bake WHILE this pose is active.
    """
    bpy.context.view_layer.objects.active = transfer
    transfer.data.pose_position = "POSE"
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.pose.transforms_clear()
    bpy.context.view_layer.update()

    # Hierarchical order: parents before children
    for pb in transfer.pose.bones:
        mb = master.data.bones.get(pb.name)
        if mb is None:
            continue
        target_world = master.matrix_world @ mb.matrix_local
        pb.matrix = transfer.matrix_world.inverted() @ target_world
    bpy.context.view_layer.update()
    bpy.ops.object.mode_set(mode="OBJECT")

    # Verify arm bones are near horizontal (T)
    for name in ("upperarm_l", "upperarm_r"):
        d = _bone_world_dir(transfer, name)
        if d is None:
            continue
        horiz = abs(d.x)
        log(f"Transfer T-pose check {name} dir=({d.x:.3f},{d.y:.3f},{d.z:.3f}) |x|={horiz:.3f}")
        if horiz < 0.85:
            log(f"WARNING: {name} not horizontal enough after T retarget")
    log("Posed UAL_TransferArmature A-rest → master T via matrix match")


def _verify_mesh_tpose(obj: bpy.types.Object, label: str) -> float:
    """Return max |arm_dir.z| penalty; lower is better (T arms are horizontal)."""
    scores = []
    for side in ("l", "r"):
        d = _mesh_arm_dir(obj, side)
        if d is None:
            log(f"WARNING {label}: no mesh arm dir for {side}")
            continue
        log(f"{label} mesh arm_{side}=({d.x:.3f},{d.y:.3f},{d.z:.3f})")
        scores.append(abs(d.z))
    return max(scores) if scores else 99.0


def _clear_pose(arm: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = arm
    try:
        bpy.ops.object.mode_set(mode="POSE")
        bpy.ops.pose.select_all(action="SELECT")
        bpy.ops.pose.transforms_clear()
        bpy.ops.object.mode_set(mode="OBJECT")
    except Exception as exc:  # noqa: BLE001
        log(f"WARNING clear pose: {exc}")
        try:
            bpy.ops.object.mode_set(mode="OBJECT")
        except Exception:  # noqa: BLE001
            pass
    bpy.context.view_layer.update()


def _ensure_armature_mod(obj: bpy.types.Object, arm: bpy.types.Object) -> None:
    for mod in list(obj.modifiers):
        if mod.type == "ARMATURE":
            obj.modifiers.remove(mod)
    mod = obj.modifiers.new(name="Armature", type="ARMATURE")
    mod.object = arm
    mod.use_vertex_groups = True
    obj.parent = arm
    obj.parent_type = "OBJECT"
    obj.matrix_parent_inverse = arm.matrix_world.inverted()


def _cleanup_vertex_groups(obj: bpy.types.Object, arm: bpy.types.Object) -> None:
    bone_names = {b.name for b in arm.data.bones}
    for vg in list(obj.vertex_groups):
        if vg.name not in bone_names:
            obj.vertex_groups.remove(vg)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
    try:
        bpy.ops.object.vertex_group_normalize_all(lock_active=False)
        bpy.ops.object.vertex_group_clean(group_select_mode="ALL", limit=0.001)
        bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
    except Exception as exc:  # noqa: BLE001
        log(f"Weight cleanup warning: {exc}")
    bpy.ops.object.mode_set(mode="OBJECT")
    weighted: set[int] = set()
    for vg in obj.vertex_groups:
        for i in range(len(obj.data.vertices)):
            try:
                vg.weight(i)
                weighted.add(i)
            except RuntimeError:
                pass
    unweighted = [i for i in range(len(obj.data.vertices)) if i not in weighted]
    if unweighted:
        fallback_name = "pelvis" if "pelvis" in bone_names else sorted(bone_names)[0]
        if fallback_name not in obj.vertex_groups:
            obj.vertex_groups.new(name=fallback_name)
        obj.vertex_groups[fallback_name].add(unweighted, 1.0, "REPLACE")
        log(f"WARNING {obj.name}: assigned {len(unweighted)} unweighted verts to {fallback_name}")


def _weight_stats(obj: bpy.types.Object, group_names: tuple[str, ...]) -> None:
    for name in group_names:
        vg = obj.vertex_groups.get(name)
        if vg is None:
            log(f"VG missing: {obj.name}.{name}")
            continue
        total = 0.0
        count = 0
        for i, v in enumerate(obj.data.vertices):
            for g in v.groups:
                if g.group == vg.index and g.weight > 0.01:
                    total += g.weight
                    count += 1
                    break
        log(f"VG {obj.name}.{name}: verts={count} weight_sum={total:.1f}")


def _geometric_arms_a_to_t(obj: bpy.types.Object, master: bpy.types.Object) -> dict[str, Matrix]:
    """
    Rotate ONLY arm-capsule vertices around the shoulder so mesh arms match
    master T-rest upperarm direction. Side-torso verts must not move (avoids batwings).
    """
    mw = obj.matrix_world
    inv = mw.inverted()
    moved = 0
    originals = [v.co.copy() for v in obj.data.vertices]
    world_pts = [mw @ co for co in originals]
    rotations: dict[str, Matrix] = {}

    for side, sign in (("l", 1.0), ("r", -1.0)):
        ua = master.data.bones.get(f"upperarm_{side}")
        if ua is None:
            continue
        shoulder = master.matrix_world @ ua.head_local
        t_dir = ((master.matrix_world @ ua.tail_local) - shoulder).normalized()

        # Wrist = farthest mesh point roughly along arm band
        tip = None
        best = -1.0
        for w in world_pts:
            if w.x * sign < 0.18:
                continue
            if w.z < 0.95 or w.z > 1.55:
                continue
            dist = (w - shoulder).length
            if dist > best:
                best = dist
                tip = w.copy()
        if tip is None or best < 0.08:
            continue

        a_dir = (tip - shoulder).normalized()
        ang = math.degrees(a_dir.angle(t_dir))
        log(f"Geometric {obj.name} arm_{side}: A→T angle {ang:.1f}° tip_dist={best:.3f}")
        if ang < 8.0:
            rotations[side] = Matrix.Identity(3)
            continue
        q = a_dir.rotation_difference(t_dir)
        R = q.to_matrix()
        rotations[side] = R.copy()

        # Elbow ~ 45% along shoulder→tip
        elbow = shoulder + a_dir * (best * 0.45)
        # Capsule radii: tight on upper arm, slightly looser on forearm
        for i, w in enumerate(world_pts):
            if w.x * sign < 0.16:
                continue
            # Must lie near shoulder→tip segment
            ab = tip - shoulder
            ab_len2 = ab.length_squared
            if ab_len2 < 1e-8:
                continue
            t = (w - shoulder).dot(ab) / ab_len2
            if t < 0.08 or t > 1.08:
                continue
            closest = shoulder + ab * t
            radial = (w - closest).length
            max_r = 0.10 if t < 0.55 else 0.12
            if radial > max_r:
                continue
            # Exclude deep torso: prefer verts outside body core
            if abs(w.x) < 0.20 and t < 0.25:
                continue
            w2 = shoulder + R @ (w - shoulder)
            obj.data.vertices[i].co = inv @ w2
            moved += 1
    obj.data.update()
    log(f"Geometric A→T on {obj.name}: touched {moved} vert slots")
    return rotations


def _apply_body_world_deltas(
    body: bpy.types.Object,
    body_before_world: list[Vector],
    target: bpy.types.Object,
    max_dist: float = 0.12,
) -> int:
    """Move target verts by the same world-space delta as the nearest *moved* body vert."""
    from mathutils.kdtree import KDTree

    mw_b = body.matrix_world
    after = [mw_b @ v.co for v in body.data.vertices]
    if len(after) != len(body_before_world):
        fail("body before/after vertex count mismatch")

    moved_idx: list[int] = []
    for i, (b, a) in enumerate(zip(body_before_world, after)):
        if (a - b).length > 1e-4:
            moved_idx.append(i)
    if not moved_idx:
        log(f"No moved body verts to propagate to {target.name}")
        return 0

    kd = KDTree(len(moved_idx))
    for ki, i in enumerate(moved_idx):
        kd.insert(body_before_world[i], ki)
    kd.balance()

    mw_t = target.matrix_world
    inv_t = mw_t.inverted()
    moved = 0
    for v in target.data.vertices:
        w = mw_t @ v.co
        _co, ki, dist = kd.find(w)
        if ki is None or dist > max_dist:
            continue
        i = moved_idx[ki]
        delta = after[i] - body_before_world[i]
        v.co = inv_t @ (w + delta)
        moved += 1
    target.data.update()
    log(f"Propagated body deltas to {target.name}: {moved} verts (max_dist={max_dist})")
    return moved


def _lbs_bake_a_rest_to_master_t(
    obj: bpy.types.Object,
    transfer_a: bpy.types.Object,
    master: bpy.types.Object,
) -> None:
    """
    Linear-blend-skin bake: verts authored against transfer A-rest bone spaces
    are rewritten into master T-rest bone spaces. Preserves vertex groups.
    """
    for mod in list(obj.modifiers):
        obj.modifiers.remove(mod)
    obj.parent = None

    deform: dict[str, Matrix] = {}
    tw = transfer_a.matrix_world
    mw = master.matrix_world
    ow = obj.matrix_world
    ow_inv = ow.inverted()
    for tb in transfer_a.data.bones:
        mb = master.data.bones.get(tb.name)
        if mb is None or not tb.use_deform:
            continue
        rest_world = tw @ tb.matrix_local
        target_world = mw @ mb.matrix_local
        deform[tb.name] = ow_inv @ target_world @ rest_world.inverted() @ ow

    vg_mats: dict[int, Matrix] = {}
    for vg in obj.vertex_groups:
        mat = deform.get(vg.name)
        if mat is not None:
            vg_mats[vg.index] = mat

    mesh = obj.data
    originals = [v.co.copy() for v in mesh.vertices]
    n_moved = 0
    for i, v in enumerate(mesh.vertices):
        acc = Vector((0.0, 0.0, 0.0))
        wsum = 0.0
        for g in v.groups:
            mat = vg_mats.get(g.group)
            if mat is None or g.weight <= 0.0:
                continue
            acc += (mat @ originals[i]) * g.weight
            wsum += g.weight
        if wsum > 1e-8:
            v.co = acc / wsum
            if (v.co - originals[i]).length > 1e-5:
                n_moved += 1
    mesh.update()
    log(f"LBS A→T bake on {obj.name}: moved {n_moved}/{len(mesh.vertices)} verts bones={len(deform)}")


def _bake_mesh_from_a_rest_to_master_t(
    obj: bpy.types.Object,
    transfer_a: bpy.types.Object,
    master: bpy.types.Object,
) -> None:
    """Prefer geometric arm lift; fall back to LBS A-rest→T if needed."""
    for mod in list(obj.modifiers):
        obj.modifiers.remove(mod)
    obj.parent = None

    moved = _geometric_arms_a_to_t(obj, master)
    if moved > 0:
        log(f"Bake {obj.name}: geometric arm lift")
        return

    # LBS fallback (requires transfer A-rest aligned with mesh)
    deform: dict[str, Matrix] = {}
    tw = transfer_a.matrix_world
    mw = master.matrix_world
    ow = obj.matrix_world
    ow_inv = ow.inverted()
    for tb in transfer_a.data.bones:
        mb = master.data.bones.get(tb.name)
        if mb is None:
            continue
        rest_world = tw @ tb.matrix_local
        target_world = mw @ mb.matrix_local
        deform[tb.name] = ow_inv @ target_world @ rest_world.inverted() @ ow

    vg_mats: dict[int, Matrix] = {}
    for vg in obj.vertex_groups:
        mat = deform.get(vg.name)
        if mat is not None:
            vg_mats[vg.index] = mat

    mesh = obj.data
    originals = [v.co.copy() for v in mesh.vertices]
    n_moved = 0
    for i, v in enumerate(mesh.vertices):
        acc = Vector((0.0, 0.0, 0.0))
        wsum = 0.0
        for g in v.groups:
            mat = vg_mats.get(g.group)
            if mat is None or g.weight <= 0.0:
                continue
            acc += mat @ originals[i] * g.weight
            wsum += g.weight
        if wsum > 1e-8:
            v.co = acc / wsum
            if (v.co - originals[i]).length > 1e-5:
                n_moved += 1
    mesh.update()
    log(f"Manual LBS A→T bake on {obj.name}: moved {n_moved}/{len(mesh.vertices)} verts")


def _bake_to_tpose(obj: bpy.types.Object, transfer: bpy.types.Object) -> None:
    """Apply Armature modifier while transfer is posed to T (mesh lifted from A-rest bind)."""
    _ensure_armature_mod(obj, transfer)
    bpy.context.view_layer.update()
    # Prefer evaluated-mesh bake (robust if modifier_apply fails on linked data)
    depsgraph = bpy.context.evaluated_depsgraph_get()
    eval_obj = obj.evaluated_get(depsgraph)
    new_mesh = bpy.data.meshes.new_from_object(eval_obj, preserve_all_data_layers=True, depsgraph=depsgraph)
    # Preserve vertex groups by copying from evaluated — new_from_object keeps them when preserve_all_data_layers
    old_mesh = obj.data
    obj.modifiers.clear()
    obj.parent = None
    obj.data = new_mesh
    if old_mesh.users == 0:
        bpy.data.meshes.remove(old_mesh)
    log(f"Baked T-pose geometry on {obj.name} (evaluated mesh, v={len(new_mesh.vertices)})")


def _probe_arm_vert_lift(obj: bpy.types.Object, arm: bpy.types.Object) -> None:
    """Log world-space movement of a heavily upperarm-weighted vertex between poses."""
    vg = obj.vertex_groups.get("upperarm_l")
    if vg is None:
        log("probe: no upperarm_l")
        return
    best_i, best_w = -1, 0.0
    for i, v in enumerate(obj.data.vertices):
        for g in v.groups:
            if g.group == vg.index and g.weight > best_w:
                best_w = g.weight
                best_i = i
    if best_i < 0:
        log("probe: no weighted vert")
        return
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    eval_obj = obj.evaluated_get(depsgraph)
    mesh = eval_obj.to_mesh()
    try:
        w = eval_obj.matrix_world @ mesh.vertices[best_i].co
        log(f"probe vert {best_i} w={best_w:.2f} world=({w.x:.3f},{w.y:.3f},{w.z:.3f}) pose_pos={arm.data.pose_position}")
        # Also log pose channel for upperarm_l
        pb = arm.pose.bones.get("upperarm_l")
        if pb:
            log(
                f"probe bone upperarm_l quat={tuple(round(x, 3) for x in pb.rotation_quaternion)}"
                f" euler={tuple(round(x, 3) for x in pb.rotation_euler)}"
                f" matrix_basis={pb.matrix_basis.to_euler('XYZ')}"
            )
    finally:
        eval_obj.to_mesh_clear()


def _snapshot_deformed_mesh(obj: bpy.types.Object, name: str) -> bpy.types.Object:
    """Duplicate object and apply modifiers so weight transfer uses deformed positions."""
    bpy.ops.object.select_all(action="DESELECT")
    obj.hide_viewport = False
    obj.hide_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.duplicate()
    dup = bpy.context.active_object
    dup.name = name
    dup.parent = None
    for mod in list(dup.modifiers):
        try:
            bpy.ops.object.modifier_apply(modifier=mod.name)
        except Exception as exc:  # noqa: BLE001
            log(f"WARNING apply mod {mod.name} on snapshot: {exc}")
            dup.modifiers.remove(mod)
    log(f"Snapshot deformed mesh {name} verts={len(dup.data.vertices)} vgroups={len(dup.vertex_groups)}")
    return dup


def _auto_weights_from_bones(obj: bpy.types.Object, arm: bpy.types.Object) -> str:
    """Heat weights against current armature rest (must match mesh pose)."""
    _ensure_armature_mod(obj, arm)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
    try:
        bpy.ops.paint.weight_from_bones(type="AUTOMATIC")
    except Exception as exc:  # noqa: BLE001
        # Fallback: parent-with-automatic-weights
        bpy.ops.object.mode_set(mode="OBJECT")
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        arm.select_set(True)
        bpy.context.view_layer.objects.active = arm
        try:
            bpy.ops.object.parent_set(type="ARMATURE_AUTO")
            log(f"weight_from_bones failed ({exc}); used ARMATURE_AUTO for {obj.name}")
            # Re-assert object parent + armature mod (parent_set may change parenting)
            _ensure_armature_mod(obj, arm)
            return "armature_auto"
        except Exception as exc2:  # noqa: BLE001
            fail(f"Auto weights failed on {obj.name}: {exc} / {exc2}")
    bpy.ops.object.mode_set(mode="OBJECT")
    return "weight_from_bones_automatic"


def _data_transfer_weights(source: bpy.types.Object, target: bpy.types.Object) -> str:
    bpy.ops.object.select_all(action="DESELECT")
    source.hide_viewport = False
    source.hide_set(False)
    target.hide_set(False)
    source.select_set(True)
    target.select_set(True)
    bpy.context.view_layer.objects.active = target
    target.vertex_groups.clear()
    mod = target.modifiers.new(name="DataTransferWeights", type="DATA_TRANSFER")
    mod.object = source
    mod.use_vert_data = True
    mod.data_types_verts = {"VGROUP_WEIGHTS"}
    mapping = "POLYINTERP_NEAREST"
    try:
        mod.vert_mapping = mapping
    except TypeError:
        mapping = "NEAREST"
        mod.vert_mapping = mapping
    mod.layers_vgroup_select_src = "ALL"
    mod.mix_mode = "REPLACE"
    bpy.ops.object.datalayout_transfer(modifier=mod.name)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return f"data_transfer_{mapping.lower()}"


def _rigid_shoes(shoes: bpy.types.Object, arm: bpy.types.Object) -> None:
    bone_names = {b.name for b in arm.data.bones}
    left = "foot_l" if "foot_l" in bone_names else sorted(bone_names)[0]
    right = "foot_r" if "foot_r" in bone_names else left
    shoes.vertex_groups.clear()
    shoes.vertex_groups.new(name=left)
    if right != left:
        shoes.vertex_groups.new(name=right)
    mw = shoes.matrix_world
    for v in shoes.data.vertices:
        w = mw @ v.co
        g = left if w.x >= 0.0 else right
        shoes.vertex_groups[g].add([v.index], 1.0, "REPLACE")
    _ensure_armature_mod(shoes, arm)
    log("Rigid-bound shoes to foot bones")


def _parent_hair(hair: bpy.types.Object, arm: bpy.types.Object) -> None:
    head = "Head" if "Head" in arm.data.bones else None
    if head is None:
        for b in arm.data.bones:
            if "head" in b.name.lower():
                head = b.name
                break
    if head is None:
        fail("Head bone missing")
    hair.vertex_groups.clear()
    vg = hair.vertex_groups.new(name=head)
    vg.add(list(range(len(hair.data.vertices))), 1.0, "REPLACE")
    _ensure_armature_mod(hair, arm)
    log(f"Hair weighted to {head}")


def _mask_body_under_clothes(body: bpy.types.Object, arm: bpy.types.Object) -> None:
    import bmesh

    neck = _bone_world_head(arm, "neck_01")
    head_z = (neck.z - 0.04) if neck is not None else 1.40
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.faces.ensure_lookup_table()
    mw = body.matrix_world
    delete_faces = []
    for f in bm.faces:
        center = Vector((0, 0, 0))
        for v in f.verts:
            center += mw @ v.co
        center /= max(len(f.verts), 1)
        if center.z >= head_z:
            continue
        if center.z > 0.92 and abs(center.x) > 0.16:
            continue
        delete_faces.append(f)
    bmesh.ops.delete(bm, geom=delete_faces, context="FACES")
    bm.to_mesh(body.data)
    bm.free()
    body.data.update()
    log(f"Masked covered body faces ({len(delete_faces)})")


def _make_material(name: str, color: tuple[float, float, float, float], roughness: float = 0.55) -> bpy.types.Material:
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = roughness
    return mat


def _assign_materials(pieces: dict[str, bpy.types.Object]) -> None:
    mats = {
        "ProxyBody": _make_material("MAT_Skin", (0.86, 0.70, 0.60, 1.0), 0.45),
        "ProxyHair": _make_material("MAT_Hair", (0.18, 0.10, 0.07, 1.0), 0.35),
        "ProxyTop": _make_material("MAT_Outfit_Primary", (0.22, 0.38, 0.55, 1.0), 0.6),
        "ProxyBottom": _make_material("MAT_Outfit_Secondary", (0.20, 0.22, 0.26, 1.0), 0.7),
        "ProxyShoes": _make_material("MAT_Shoes", (0.12, 0.12, 0.12, 1.0), 0.55),
    }
    for key, obj in pieces.items():
        mat = mats.get(key)
        if mat is None:
            continue
        obj.data.materials.clear()
        obj.data.materials.append(mat)


def _copy_nla(src: bpy.types.Object, dst: bpy.types.Object) -> list[str]:
    if src.animation_data is None:
        return []
    if dst.animation_data is None:
        dst.animation_data_create()
    while dst.animation_data.nla_tracks:
        dst.animation_data.nla_tracks.remove(dst.animation_data.nla_tracks[0])
    names: list[str] = []
    for tr in src.animation_data.nla_tracks:
        new_tr = dst.animation_data.nla_tracks.new(prev=None)
        new_tr.name = tr.name
        names.append(tr.name)
        for strip in tr.strips:
            if strip.action is None:
                continue
            new_strip = new_tr.strips.new(strip.name, int(strip.frame_start), strip.action)
            new_strip.frame_end = strip.frame_end
            if hasattr(strip, "action_slot") and hasattr(new_strip, "action_slot"):
                try:
                    new_strip.action_slot = strip.action_slot
                except Exception:  # noqa: BLE001
                    pass
    return names


def _import_ual(ual_path: Path, master: bpy.types.Object) -> list[str]:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(ual_path))
    imported = [o for o in bpy.data.objects if o not in before]
    ual_arms = [o for o in imported if o.type == "ARMATURE"]
    if not ual_arms:
        fail("UAL import produced no armature")
    names = _copy_nla(ual_arms[0], master)
    for obj in imported:
        bpy.data.objects.remove(obj, do_unlink=True)
    log(f"Copied UAL NLA tracks: {names[:30]}")
    return names


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
        return Vector(), Vector((1, 1, 1.8)), Vector((0, 0, 0.9))
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return mn, mx, (mn + mx) * 0.5


def _camera(view: str, mn: Vector, mx: Vector, center: Vector) -> None:
    cam = bpy.data.objects.get("FIX_Cam")
    if cam is None:
        data = bpy.data.cameras.new("FIX_Cam")
        cam = bpy.data.objects.new("FIX_Cam", data)
        bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    size = mx - mn
    height = max(size.z, 0.5)
    width = max(size.x, size.y, 0.5)
    dist = max(height * 2.5, width * 2.6, 3.2)
    target = Vector((center.x, center.y, mn.z + height * 0.52))
    if view == "FRONT":
        cam.location = (target.x, target.y - dist, target.z)
    elif view == "SIDE":
        cam.location = (target.x + dist, target.y, target.z)
    else:
        cam.location = (target.x + dist * 0.7, target.y - dist * 0.7, target.z)
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = 50.0


def _play(arm: bpy.types.Object, action_name: str | None, frame: int) -> None:
    if not arm.animation_data:
        arm.animation_data_create()
    ad = arm.animation_data
    for tr in ad.nla_tracks:
        tr.mute = True
    _clear_pose(arm)
    arm.data.pose_position = "POSE"
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
        if match and match.strips:
            match.mute = False
            strip = match.strips[0]
            ad.action = strip.action
            if hasattr(ad, "action_slot") and hasattr(strip, "action_slot"):
                try:
                    ad.action_slot = strip.action_slot
                except Exception:  # noqa: BLE001
                    pass
        else:
            ad.action = None
    else:
        ad.action = None
        arm.data.pose_position = "REST"
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()


def _render(path: Path, arm: bpy.types.Object, meshes: list[bpy.types.Object], view: str, wire: bool = False) -> None:
    sc = bpy.context.scene
    arm.show_in_front = True
    if wire:
        for obj in meshes:
            if obj and obj.type == "MESH":
                obj.display_type = "WIRE"
        arm.data.display_type = "OCTAHEDRAL"
    else:
        for obj in meshes:
            if obj and obj.type == "MESH":
                obj.display_type = "TEXTURED"
    mn, mx, center = _eval_bbox([m for m in meshes if m])
    _camera(view, mn, mx, center)
    sc.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    for obj in meshes:
        if obj and obj.type == "MESH":
            obj.display_type = "TEXTURED"
    log(f"Rendered {path.name}")


def _setup_render() -> None:
    sc = bpy.context.scene
    _set_engine(sc)
    sc.render.resolution_x = 1280
    sc.render.resolution_y = 720
    if sc.world is None:
        sc.world = bpy.data.worlds.new("FIX_World")
    sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.08, 0.09, 0.11, 1.0)
    if not bpy.data.objects.get("FIX_Light"):
        light = bpy.data.lights.new("FIX_Light", type="AREA")
        light.energy = 900
        light.size = 3.5
        lob = bpy.data.objects.new("FIX_Light", light)
        bpy.context.collection.objects.link(lob)
        lob.location = (2.5, -2.5, 3.5)
    if not bpy.data.objects.get("FIX_Fill"):
        fill = bpy.data.lights.new("FIX_Fill", type="AREA")
        fill.energy = 250
        fill.size = 4.0
        fob = bpy.data.objects.new("FIX_Fill", fill)
        bpy.context.collection.objects.link(fob)
        fob.location = (-2.0, 1.5, 2.0)


def _export_glb(path: Path, master: bpy.types.Object, pieces: dict[str, bpy.types.Object]) -> None:
    # Re-resolve live objects (save/ops may invalidate RNA pointers).
    master_live = bpy.data.objects.get(master.name) or bpy.data.objects.get("UAL_MasterArmature")
    if master_live is None:
        arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
        if not arms:
            fail("No master armature for export")
        master_live = arms[0]
        master_live.name = "UAL_MasterArmature"

    for name in list(bpy.data.objects.keys()):
        obj = bpy.data.objects.get(name)
        if obj is None:
            continue
        if obj.name.startswith("UAL_Transfer") or obj.name.startswith("Donor") or obj.name.startswith("TechChair"):
            bpy.data.objects.remove(obj, do_unlink=True)
            continue
        if obj.type == "MESH":
            base = obj.name.split(".")[0]
            if base not in PROXY_MESHES:
                bpy.data.objects.remove(obj, do_unlink=True)

    bpy.ops.object.select_all(action="DESELECT")
    master_live.select_set(True)
    for key in PROXY_MESHES:
        obj = bpy.data.objects.get(key)
        if obj is None:
            fail(f"Missing {key} for export")
        obj.select_set(True)
        obj.hide_set(False)
        obj.hide_render = False
        pieces[key] = obj
    bpy.context.view_layer.objects.active = master_live
    _clear_pose(master_live)
    master_live.data.pose_position = "REST"
    if master_live.animation_data:
        master_live.animation_data.action = None
        for tr in master_live.animation_data.nla_tracks:
            tr.mute = True
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        use_selection=True,
        export_format="GLB",
        export_animations=True,
        export_skins=True,
        export_morph=False,
        export_apply=False,
        export_extras=False,
    )
    log(f"Exported {path}")


def _dedupe_glb(path: Path) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    if len(arms) > 1:
        keep = arms[0]
        for arm in arms[1:]:
            for child in list(arm.children_recursive):
                bpy.data.objects.remove(child, do_unlink=True)
            bpy.data.objects.remove(arm, do_unlink=True)
        keep.name = "UAL_MasterArmature"
    keep_names = set(PROXY_MESHES)
    seen: set[str] = set()
    for obj in list(bpy.data.objects):
        if obj.type != "MESH":
            continue
        base = obj.name.split(".")[0]
        if base not in keep_names or base in seen:
            bpy.data.objects.remove(obj, do_unlink=True)
        else:
            seen.add(base)
            obj.name = base
    # Verify rest: clear pose
    arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    if arms:
        arms[0].data.pose_position = "REST"
        _clear_pose(arms[0])
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.data.objects:
        if obj.type in {"ARMATURE", "MESH"}:
            obj.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        use_selection=True,
        export_format="GLB",
        export_animations=True,
        export_skins=True,
        export_morph=False,
        export_apply=False,
        export_extras=False,
    )
    log(f"Dedupe+reimport verify export done arms={len(arms)} meshes={sorted(seen)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    add_common_args(parser)
    args = parser.parse_args(parse_argv_after_double_dash())
    out = ensure_dir(args.output)
    diag = ensure_dir(out / "trest_fix")
    proxy = require_file(args.proxy, "proxy blend")
    donor_path = require_file(args.donor, "donor")
    ual = require_file(args.ual, "UAL")

    _clear_scene()
    master, donor_body = _import_donor(donor_path)
    # Master must stay T-rest forever
    master.data.pose_position = "REST"
    _clear_pose(master)

    transfer = _duplicate_transfer_armature(master)
    # Point donor deformation at transfer for A-pose weight source
    for mod in donor_body.modifiers:
        if mod.type == "ARMATURE":
            mod.object = transfer
    donor_body.parent = transfer
    donor_body.matrix_parent_inverse = transfer.matrix_world.inverted()

    wanted = [SELECTION["body"], SELECTION["hair"], SELECTION["top"], SELECTION["bottom"], SELECTION["shoes"]]
    appended = _append_proxy(proxy, wanted)
    rename = {
        SELECTION["body"]: "ProxyBody",
        SELECTION["hair"]: "ProxyHair",
        SELECTION["top"]: "ProxyTop",
        SELECTION["bottom"]: "ProxyBottom",
        SELECTION["shoes"]: "ProxyShoes",
    }
    pieces: dict[str, bpy.types.Object] = {}
    for old, new in rename.items():
        obj = appended.get(old)
        if obj is None:
            for k, v in appended.items():
                if k.lower() == old.lower():
                    obj = v
                    break
        if obj is None:
            fail(f"Missing {old}")
        obj.name = new
        pieces[new] = obj

    _fit_proxy_set(pieces, donor_body, master)

    # Pose transfer to A matching Proxy
    _pose_transfer_to_proxy_a(transfer, pieces["ProxyBody"])
    donor_body.hide_viewport = False
    donor_body.hide_set(False)
    bpy.context.view_layer.update()

    # Overlay render while in A-pose match
    _setup_render()
    donor_body.hide_render = False
    _play(transfer, None, 1)
    transfer.data.pose_position = "POSE"
    # Re-apply A pose after _play cleared it
    _pose_transfer_to_proxy_a(transfer, pieces["ProxyBody"])
    meshes_overlay = [pieces["ProxyBody"], donor_body, pieces["ProxyTop"]]
    _render(diag / "transfer_a_pose_overlay.png", transfer, meshes_overlay, "FRONT", wire=False)
    donor_body.hide_render = True

    # --- Canonical pipeline ---
    # A-pose aim (0° err) → Apply Pose as Rest on TRANSFER only → auto-weight →
    # LBS bake A-rest→master T → bind clean master.
    _pose_transfer_to_proxy_a(transfer, pieces["ProxyBody"])
    saved_a = _save_pose_quats(transfer)
    log(f"Saved {len(saved_a)} A-pose quats: {sorted(saved_a)}")

    # Verify aim before committing rest (compare bone to elbow aim target)
    for side in ("l", "r"):
        _sh, elbow_m, _wr = _mesh_arm_joints(pieces["ProxyBody"], side)
        d = _bone_world_dir(transfer, f"upperarm_{side}")
        if d and elbow_m is not None:
            pb = transfer.pose.bones.get(f"upperarm_{side}")
            head = transfer.matrix_world @ pb.head
            mesh_d = (elbow_m - head).normalized()
            ang = math.degrees(d.angle(mesh_d))
            log(f"Pre-rest aim check upperarm_{side}: bone/elbow err={ang:.1f}°")
            if ang > 15.0:
                fail(f"A-pose aim too poor on upperarm_{side} ({ang:.1f}°)")

    _apply_pose_as_rest_transfer_only(transfer)
    # Confirm transfer rest is A (not T)
    for side in ("l", "r"):
        d = _bone_world_dir(transfer, f"upperarm_{side}")
        if d:
            log(f"Transfer A-rest upperarm_{side} dir=({d.x:.3f},{d.y:.3f},{d.z:.3f}) |z|={abs(d.z):.3f}")
            if abs(d.z) < 0.25:
                fail("Transfer rest still looks T after Apply Pose as Rest")

    methods = {}
    methods["ProxyBody"] = _auto_weights_from_bones(pieces["ProxyBody"], transfer)
    _cleanup_vertex_groups(pieces["ProxyBody"], master)
    _weight_stats(pieces["ProxyBody"], ("upperarm_l", "upperarm_r", "lowerarm_l", "lowerarm_r", "hand_l", "hand_r"))

    for key in ("ProxyTop", "ProxyBottom"):
        methods[key] = _data_transfer_weights(pieces["ProxyBody"], pieces[key])
        _cleanup_vertex_groups(pieces[key], master)
    methods["ProxyShoes"] = "rigid_feet"

    bpy.ops.wm.save_as_mainfile(filepath=str(out / "DEBUG_pre_bake.blend"))
    log("Saved DEBUG_pre_bake.blend")

    # LBS bake: express verts in transfer A-rest bone spaces, place into master T-rest
    for key in BAKE_MESHES:
        for mod in list(pieces[key].modifiers):
            pieces[key].modifiers.remove(mod)
        pieces[key].parent = None
        _lbs_bake_a_rest_to_master_t(pieces[key], transfer, master)

    z_baked = _verify_mesh_tpose(pieces["ProxyBody"], "LBS T mesh")
    log(f"LBS T mesh |z| max={z_baked:.3f} (expect low ~0.1)")
    master.data.pose_position = "REST"
    _clear_pose(master)
    _render(
        diag / "during_t_pose_before_bake.png",
        master,
        [pieces["ProxyBody"], pieces["ProxyTop"]],
        "FRONT",
        wire=True,
    )
    if z_baked > 0.35:
        bpy.ops.wm.save_as_mainfile(filepath=str(out / "DEBUG_trest_fail.blend"))
        fail(f"LBS bake did not produce T-pose mesh (|z|={z_baked:.3f})")

    # Bind baked T-meshes to clean master
    for key in BAKE_MESHES:
        _ensure_armature_mod(pieces[key], master)
    _rigid_shoes(pieces["ProxyShoes"], master)
    _parent_hair(pieces["ProxyHair"], master)
    _mask_body_under_clothes(pieces["ProxyBody"], master)
    _assign_materials(pieces)

    junk = bpy.data.objects.get("UAL_TransferArmature")
    if junk:
        bpy.data.objects.remove(junk, do_unlink=True)
    donor_body.hide_viewport = True
    donor_body.hide_render = True

    # Import UAL clips onto master
    action_names = _import_ual(ual, master)
    _clear_pose(master)
    master.data.pose_position = "REST"
    if master.animation_data:
        master.animation_data.action = None
        for tr in master.animation_data.nla_tracks:
            tr.mute = True

    # After rest proofs
    proxy_list = [pieces[k] for k in PROXY_MESHES]
    master.show_in_front = True
    _play(master, None, 1)
    master.data.pose_position = "REST"
    _render(diag / "after_rest_pose_front.png", master, proxy_list, "FRONT")
    _render(diag / "after_rest_pose_side.png", master, proxy_list, "SIDE")
    _render(diag / "after_rest_pose_wire.png", master, proxy_list, "FRONT", wire=True)

    # Animation proofs
    frames = [
        ("fixed_01_idle_front.png", "Idle_Loop", "FRONT", 8),
        ("fixed_02_walk_front.png", "Walk_Loop", "FRONT", 12),
        ("fixed_03_walk_side.png", "Walk_Loop", "SIDE", 12),
        ("fixed_04_sit_enter_side.png", "Sitting_Enter", "SIDE", 10),
        ("fixed_05_sit_idle_side.png", "Sitting_Idle_Loop", "SIDE", 8),
        ("fixed_06_seated_gesture_front.png", "Sitting_Talking_Loop", "FRONT", 10),
        ("fixed_07_sit_exit_side.png", "Sitting_Exit", "SIDE", 10),
    ]
    for filename, action, view, frame in frames:
        _play(master, action, frame)
        _render(diag / filename, master, proxy_list, view)

    # Save working blend for T-rest fix
    working = out / "ProxyGirl_POC_TRest_Working.blend"
    _clear_pose(master)
    master.data.pose_position = "REST"
    if master.animation_data:
        master.animation_data.action = None
        for tr in master.animation_data.nla_tracks:
            tr.mute = True
    # Ensure no transfer left
    junk = bpy.data.objects.get("UAL_TransferArmature")
    if junk:
        bpy.data.objects.remove(junk, do_unlink=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(working))
    log(f"Saved {working}")

    glb = out / "GirlProxyPOC_TRest.glb"
    _export_glb(glb, master, pieces)
    _dedupe_glb(glb)

    # Rest verify report from reimported scene state after dedupe
    report = {
        "status_candidate": "PENDING_VISUAL_QA",
        "selection": SELECTION,
        "weight_methods": methods,
        "ual_actions": action_names,
        "working_blend": str(working),
        "glb": str(glb),
        "pipeline": "A-pose garment → skin in matching A-pose → deform to T-pose → bake geometry → bind to clean T-rest armature",
        "blender": bpy.app.version_string,
    }
    write_json(diag / "trest_fix_report.json", report)
    write_json(out / "trest_fix_report.json", report)
    log("T-rest fix build complete")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        fail(f"Unhandled trest fix error: {exc}")
