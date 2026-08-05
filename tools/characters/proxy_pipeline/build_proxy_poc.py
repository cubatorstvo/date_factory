"""
Build ProxyGirl POC:
- Keep UAL-compatible donor Armature unchanged
- Fit Proxy meshes to donor body
- Transfer weights (Data Transfer)
- Assign materials
- Export GirlProxyPOC.glb
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
from mathutils import Matrix, Vector  # noqa: E402

from poc_selection import SELECTION  # noqa: E402
from proxy_paths import (  # noqa: E402
    UAL_CLIP_NAMES,
    add_common_args,
    ensure_dir,
    fail,
    log,
    parse_argv_after_double_dash,
    require_file,
    write_json,
)


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


def _apply_constructive_modifiers(obj: bpy.types.Object) -> None:
    """Apply Mirror; remove Solidify (inner shells create wing artifacts)."""
    if obj.type != "MESH":
        return
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    for mod in list(obj.modifiers):
        if mod.type == "MIRROR":
            try:
                bpy.ops.object.modifier_apply(modifier=mod.name)
                log(f"Applied MIRROR on {obj.name}")
            except Exception as exc:  # noqa: BLE001
                log(f"WARNING could not apply MIRROR on {obj.name}: {exc}")
                obj.modifiers.remove(mod)
        elif mod.type == "SOLIDIFY":
            log(f"Removing SOLIDIFY on {obj.name} (keep thin shell for clean weights)")
            obj.modifiers.remove(mod)
        elif mod.type in {"SUBSURF", "BEVEL", "TRIANGULATE", "WEIGHTED_NORMAL"}:
            try:
                bpy.ops.object.modifier_apply(modifier=mod.name)
                log(f"Applied {mod.type} on {obj.name}")
            except Exception as exc:  # noqa: BLE001
                log(f"WARNING could not apply {mod.type} on {obj.name}: {exc}")
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


def _verts_near_bone_chain(
    bm,
    mw,
    arm: bpy.types.Object,
    bone_names: list[str],
    radius: float,
) -> list[int]:
    """Indices of verts within radius of any bone segment (rest pose)."""
    segments: list[tuple[Vector, Vector]] = []
    for name in bone_names:
        h = _bone_world_head(arm, name)
        t = _bone_world_tail(arm, name)
        if h is None or t is None:
            continue
        segments.append((h, t))
    if not segments:
        return []
    idxs: list[int] = []
    for v in bm.verts:
        w = mw @ v.co
        for a, b in segments:
            ab = b - a
            den = ab.length_squared
            if den < 1e-10:
                dist = (w - a).length
            else:
                t = max(0.0, min(1.0, (w - a).dot(ab) / den))
                dist = (w - (a + ab * t)).length
            if dist <= radius:
                idxs.append(v.index)
                break
    return idxs


def _rotate_verts_around(bm, mw, imw, indices: list[int], pivot: Vector, quat) -> int:
    moved = 0
    for idx in indices:
        v = bm.verts[idx]
        w = mw @ v.co
        w2 = pivot + quat @ (w - pivot)
        v.co = imw @ w2
        moved += 1
    return moved


def _temp_pose_armature_to_aprox(arm: bpy.types.Object) -> None:
    """
    Drop T-pose arms ~40° toward A-pose so Data Transfer lines up with Proxy
    without permanently reshaping Proxy mesh volume.
    """
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.pose.transforms_clear()
    # Quaternius upperarm: rotate around local bone axis to lower the arm in front view.
    # Empirically ~+0.70 / -0.70 rad on X works for this UAL armature.
    for name, angle in (("upperarm_l", 0.70), ("upperarm_r", -0.70)):
        pb = arm.pose.bones.get(name)
        if pb is None:
            continue
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = (angle, 0.0, 0.0)
    bpy.context.view_layer.update()
    bpy.ops.object.mode_set(mode="OBJECT")
    log("Temporarily posed armature arms toward A-pose for weight transfer")


def _clear_armature_pose(arm: bpy.types.Object) -> None:
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
    bpy.context.view_layer.update()


def _reshape_clothes_to_body(
    cloth: bpy.types.Object,
    body: bpy.types.Object,
    offset: float = 0.012,
    max_distance: float | None = 0.08,
) -> None:
    """Mild shrinkwrap onto Proxy body (both stay in authored A-pose)."""
    bpy.ops.object.select_all(action="DESELECT")
    cloth.select_set(True)
    bpy.context.view_layer.objects.active = cloth
    mod = cloth.modifiers.new(name="SW_FitBody", type="SHRINKWRAP")
    mod.target = body
    mod.wrap_method = "NEAREST_SURFACEPOINT"
    mod.wrap_mode = "ABOVE_SURFACE"
    mod.offset = offset
    if max_distance is not None and hasattr(mod, "use_max_distance"):
        mod.use_max_distance = True
        mod.max_distance = max_distance
    try:
        bpy.ops.object.modifier_apply(modifier=mod.name)
        log(f"Shrinkwrap-fit {cloth.name} to body offset={offset} max_d={max_distance}")
    except Exception as exc:  # noqa: BLE001
        log(f"WARNING shrinkwrap failed on {cloth.name}: {exc}")
        if mod.name in cloth.modifiers:
            cloth.modifiers.remove(mod)


def _sanitize_shoe_weights(shoes: bpy.types.Object, arm: bpy.types.Object) -> None:
    """
    Keep only lower-leg / foot bones per side. Mixed spine/thigh weights cause
    jagged spikes when feet plant during walk.
    """
    bone_names = {b.name for b in arm.data.bones}
    # Quaternius: +X ≈ left
    left_bones = {b for b in ("thigh_l", "calf_l", "foot_l", "ball_l") if b in bone_names}
    right_bones = {b for b in ("thigh_r", "calf_r", "foot_r", "ball_r") if b in bone_names}
    for name in left_bones | right_bones:
        if name not in shoes.vertex_groups:
            shoes.vertex_groups.new(name=name)

    mw = shoes.matrix_world
    fixed = 0
    for v in shoes.data.vertices:
        wpos = mw @ v.co
        allowed = left_bones if wpos.x >= 0.0 else right_bones
        prefer = {b for b in allowed if b.startswith(("foot_", "ball_", "calf_"))}
        if wpos.z > 0.18:
            prefer |= {b for b in allowed if b.startswith("thigh_")}
        weights: dict[str, float] = {}
        for g in list(v.groups):
            gname = shoes.vertex_groups[g.group].name
            if gname in prefer:
                weights[gname] = g.weight
            shoes.vertex_groups[g.group].remove([v.index])
        if not weights:
            fb = "foot_l" if wpos.x >= 0.0 else "foot_r"
            if fb not in shoes.vertex_groups:
                shoes.vertex_groups.new(name=fb)
            shoes.vertex_groups[fb].add([v.index], 1.0, "REPLACE")
            fixed += 1
            continue
        total = sum(weights.values()) or 1.0
        for gname, wt in weights.items():
            shoes.vertex_groups[gname].add([v.index], wt / total, "REPLACE")
        fixed += 1
    _cleanup_vertex_groups(shoes, arm)
    log(f"Sanitized shoe weights on {shoes.name} ({fixed} verts)")


def _sanitize_top_sleeve_weights(top: bpy.types.Object, arm: bpy.types.Object) -> None:
    """Strip pelvis/spine dominance from outer sleeve verts so arms raise cleanly."""
    arm_bones = {
        "clavicle_l",
        "clavicle_r",
        "upperarm_l",
        "upperarm_r",
        "lowerarm_l",
        "lowerarm_r",
        "hand_l",
        "hand_r",
        "spine_03",
        "spine_02",
    }
    bone_names = {b.name for b in arm.data.bones}
    arm_bones = {b for b in arm_bones if b in bone_names}
    bad = {"pelvis", "spine_01", "thigh_l", "thigh_r", "calf_l", "calf_r"}
    mw = top.matrix_world
    fixed = 0
    for v in top.data.vertices:
        wpos = mw @ v.co
        if abs(wpos.x) < 0.22:
            continue
        if wpos.z < 1.05 or wpos.z > 1.55:
            continue
        kept: dict[str, float] = {}
        for g in list(v.groups):
            gname = top.vertex_groups[g.group].name
            if gname in bad:
                top.vertex_groups[g.group].remove([v.index])
                continue
            if gname in arm_bones or gname.startswith("upperarm") or gname.startswith("lowerarm") or gname.startswith("hand_") or gname.startswith("clavicle"):
                kept[gname] = g.weight
        if kept:
            for g in list(v.groups):
                top.vertex_groups[g.group].remove([v.index])
            total = sum(kept.values()) or 1.0
            for gname, wt in kept.items():
                if gname not in top.vertex_groups:
                    top.vertex_groups.new(name=gname)
                top.vertex_groups[gname].add([v.index], wt / total, "REPLACE")
            fixed += 1
    if fixed:
        _cleanup_vertex_groups(top, arm)
    log(f"Sanitized top sleeve weights ({fixed} verts)")


def _find_armature() -> bpy.types.Object:
    arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    if not arms:
        fail("No Armature found after donor import")
    # Prefer named CharacterArmature / Armature
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
        fail("Donor body mesh not found")
    return meshes[0]


def _import_donor(donor_path: Path) -> tuple[bpy.types.Object, bpy.types.Object]:
    log(f"Import donor: {donor_path}")
    before = set(bpy.data.objects)
    if donor_path.suffix.lower() in {".glb", ".gltf"}:
        bpy.ops.import_scene.gltf(filepath=str(donor_path))
    else:
        fail(f"Unsupported donor format: {donor_path}")
    after = [o for o in bpy.data.objects if o not in before]
    log(f"Donor imported objects: {[o.name for o in after]}")
    arm = _find_armature()
    body = _find_donor_body(arm)
    body.name = "DonorBody_PACK021"
    arm.name = "UAL_MasterArmature"
    # Remove non-body donor clutter (eyes/brows/helpers) so they never export or render.
    for obj in list(after):
        if obj == arm or obj == body:
            continue
        if obj.type == "MESH":
            log(f"Removing donor clutter mesh: {obj.name}")
            bpy.data.objects.remove(obj, do_unlink=True)
    # Freeze donor as weight source; keep invisible
    body.hide_render = True
    body.hide_viewport = True
    return arm, body


def _append_proxy_objects(proxy_blend: Path, names: list[str]) -> dict[str, bpy.types.Object]:
    log(f"Append from proxy: {names}")
    with bpy.data.libraries.load(str(proxy_blend), link=False) as (data_from, data_to):
        available = set(data_from.objects)
        missing = [n for n in names if n not in available]
        if missing:
            # fuzzy match
            lowered = {n.lower(): n for n in available}
            resolved = []
            for n in names:
                if n in available:
                    resolved.append(n)
                elif n.lower() in lowered:
                    resolved.append(lowered[n.lower()])
                else:
                    fail(f"Proxy object not found in blend: {n}. Available sample: {sorted(available)[:30]}")
            names = resolved
        data_to.objects = names
    linked: dict[str, bpy.types.Object] = {}
    for obj in data_to.objects:
        if obj is None:
            continue
        bpy.context.collection.objects.link(obj)
        linked[obj.name] = obj
        log(f"Appended {obj.name} type={obj.type} verts={len(obj.data.vertices) if obj.type=='MESH' else 0}")
    return linked


def _fit_mesh_to_donor(src: bpy.types.Object, donor: bpy.types.Object, mode: str = "body") -> Matrix:
    """Legacy single-mesh fit — prefer _fit_proxy_set_to_donor."""
    d_min, d_max, d_c = _bbox(donor)
    s_min, s_max, s_c = _bbox(src)
    d_size = d_max - d_min
    s_size = s_max - s_min
    scale = d_size.z / max(s_size.z, 1e-6)
    src.scale = (src.scale.x * scale, src.scale.y * scale, src.scale.z * scale)
    bpy.context.view_layer.update()
    s_min, s_max, s_c = _bbox(src)
    delta = Vector((d_c.x - s_c.x, d_c.y - s_c.y, d_min.z - s_min.z))
    src.location += delta
    bpy.context.view_layer.update()
    _apply_object_transforms(src)
    return Matrix.Identity(4)


def _clear_shape_keys(obj: bpy.types.Object) -> None:
    """Shape keys block modifier apply; Proxy Base Model often carries them."""
    if obj.type != "MESH" or obj.data.shape_keys is None:
        return
    obj.shape_key_clear()
    log(f"Cleared shape keys on {obj.name}")


def _fit_proxy_set_to_donor(pieces: dict[str, bpy.types.Object], donor: bpy.types.Object, arm: bpy.types.Object) -> None:
    """
    Proxy assets share one authored scale. Uniform-fit to donor height/floor.
    Keep Proxy A-pose mesh volume — arm pose mismatch is handled by temporarily
    posing the armature during weight transfer (not by editing Proxy verts).
    """
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
        obj.scale = (obj.scale.x * scale, obj.scale.y * scale, obj.scale.z * scale)
    bpy.context.view_layer.update()
    b_min, b_max, b_c = _bbox(body)
    delta = Vector((d_c.x - b_c.x, d_c.y - b_c.y, d_min.z - b_min.z))
    for obj in pieces.values():
        obj.location += delta
    bpy.context.view_layer.update()
    for obj in pieces.values():
        _apply_object_transforms(obj)

    # Clothes stay authored A-pose; mild shrinkwrap only.
    _reshape_clothes_to_body(pieces["ProxyTop"], body, offset=0.014, max_distance=0.08)
    _reshape_clothes_to_body(pieces["ProxyBottom"], body, offset=0.022, max_distance=0.12)
    _reshape_clothes_to_body(pieces["ProxyShoes"], body, offset=0.008, max_distance=0.06)

    # Place hair on head landmark (translate only — no mesh reshape).
    hair = pieces["ProxyHair"]
    head = _bone_world_head(arm, "Head")
    if head is not None:
        h_min, h_max, h_c = _bbox(hair)
        hair.location += Vector((head.x - h_c.x, head.y - h_c.y, (head.z + 0.08) - h_c.z))
        bpy.context.view_layer.update()
        _apply_object_transforms(hair)

    shoes = pieces["ProxyShoes"]
    s_min, s_max, s_c = _bbox(shoes)
    foot_l = _bone_world_head(arm, "foot_l")
    foot_r = _bone_world_head(arm, "foot_r")
    if foot_l and foot_r:
        mid = (foot_l + foot_r) * 0.5
        shoes.location += Vector((mid.x - s_c.x, mid.y - s_c.y, d_min.z - s_min.z))
        bpy.context.view_layer.update()
        _apply_object_transforms(shoes)

    b_min, b_max, b_c = _bbox(body)
    log(
        f"Fit done body_size={[round(x,3) for x in (b_max-b_min)]} "
        f"donor_size={[round(x,3) for x in d_size]} (kept Proxy A-pose volume)"
    )


def _ensure_armature_modifier(obj: bpy.types.Object, arm: bpy.types.Object) -> None:
    for mod in list(obj.modifiers):
        if mod.type == "ARMATURE":
            obj.modifiers.remove(mod)
    mod = obj.modifiers.new(name="Armature", type="ARMATURE")
    mod.object = arm
    mod.use_vertex_groups = True
    # Always Object-parent (never Armature parent) to avoid double deformation.
    obj.parent = arm
    obj.parent_type = "OBJECT"
    obj.matrix_parent_inverse = arm.matrix_world.inverted()


def _limb_weight_score(obj: bpy.types.Object, arm: bpy.types.Object) -> float:
    """Higher is better: outer arm verts should carry arm bone weights, not pelvis."""
    mw = obj.matrix_world
    if _bone_world_head(arm, "hand_l") is None:
        return 0.0
    arm_bones = {
        "upperarm_l",
        "lowerarm_l",
        "hand_l",
        "upperarm_r",
        "lowerarm_r",
        "hand_r",
        "clavicle_l",
        "clavicle_r",
    }
    score = 0.0
    samples = 0
    for v in obj.data.vertices:
        w = mw @ v.co
        if abs(w.x) < 0.35:
            continue
        if w.z < 1.0 or w.z > 1.55:
            continue
        samples += 1
        arm_w = 0.0
        bad_w = 0.0
        for g in v.groups:
            name = obj.vertex_groups[g.group].name
            if name in arm_bones:
                arm_w += g.weight
            if name in {"pelvis", "root", "thigh_l", "thigh_r"}:
                bad_w += g.weight
        score += arm_w - bad_w
    if samples == 0:
        return 0.0
    return score / samples


def _automatic_weights(target: bpy.types.Object, arm: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    target.parent = None
    target.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    target.vertex_groups.clear()
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    # Convert away from Armature-parent to Object-parent + modifier.
    _ensure_armature_modifier(target, arm)


def _data_transfer_weights(source: bpy.types.Object, target: bpy.types.Object, mapping: str = "POLYINTERP_NEAREST") -> str:
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


def _count_unweighted(obj: bpy.types.Object) -> int:
    weighted = set()
    for vg in obj.vertex_groups:
        for i in range(len(obj.data.vertices)):
            try:
                vg.weight(i)
                weighted.add(i)
            except RuntimeError:
                pass
    return len(obj.data.vertices) - len(weighted)


def _transfer_weights(source: bpy.types.Object, target: bpy.types.Object, arm: bpy.types.Object) -> str:
    """
    Prefer Data Transfer from an already-fitted source mesh.
    Automatic Weights only kept when they clearly produce fewer unweighted verts
    and a better limb score.
    """
    # Primary: Data Transfer
    try:
        method = _data_transfer_weights(source, target)
    except Exception as exc:  # noqa: BLE001
        log(f"Data Transfer failed ({exc}); using Automatic Weights")
        _automatic_weights(target, arm)
        _cleanup_vertex_groups(target, arm)
        _ensure_armature_modifier(target, arm)
        return "automatic_weights_fallback"

    _cleanup_vertex_groups(target, arm)
    dt_unweighted = _count_unweighted(target)
    dt_score = _limb_weight_score(target, arm)
    log(f"{target.name} data-transfer score={dt_score:.3f} unweighted={dt_unweighted}")

    # Optional auto comparison for body-like meshes only
    if target.name == "ProxyBody":
        # Snapshot groups
        _automatic_weights(target, arm)
        _cleanup_vertex_groups(target, arm)
        auto_unweighted = _count_unweighted(target)
        auto_score = _limb_weight_score(target, arm)
        log(f"{target.name} auto score={auto_score:.3f} unweighted={auto_unweighted}")
        if auto_score > dt_score + 0.05 and auto_unweighted <= dt_unweighted:
            method = "automatic_weights_better"
        else:
            method = _data_transfer_weights(source, target)
            _cleanup_vertex_groups(target, arm)
            method = f"{method}_kept"

    _ensure_armature_modifier(target, arm)
    final_u = _count_unweighted(target)
    if final_u:
        log(f"WARNING {target.name}: still {final_u} unweighted after transfer")
    log(f"{target.name} final weights via {method}")
    return method


def _cleanup_vertex_groups(obj: bpy.types.Object, arm: bpy.types.Object) -> None:
    bone_names = {b.name for b in arm.data.bones}
    # Remove unknown groups
    for vg in list(obj.vertex_groups):
        if vg.name not in bone_names:
            obj.vertex_groups.remove(vg)
    # Normalize / limit
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
    # Unweighted vertex check
    weighted = set()
    for vg in obj.vertex_groups:
        for i, v in enumerate(obj.data.vertices):
            try:
                vg.weight(i)
                weighted.add(i)
            except RuntimeError:
                pass
    unweighted = [i for i in range(len(obj.data.vertices)) if i not in weighted]
    if unweighted:
        log(f"WARNING {obj.name}: {len(unweighted)} unweighted verts (will assign to Hips/Spine if present)")
        # Assign leftovers to Hips or first spine bone
        fallback = None
        for candidate in ("Hips", "hips", "Spine", "spine", "Root"):
            if candidate in obj.vertex_groups:
                fallback = obj.vertex_groups[candidate]
                break
            if candidate in bone_names:
                fallback = obj.vertex_groups.new(name=candidate)
                break
        if fallback is None and bone_names:
            fallback = obj.vertex_groups.new(name=sorted(bone_names)[0])
        if fallback is not None:
            fallback.add(unweighted, 1.0, "REPLACE")


def _parent_hair_to_head(hair: bpy.types.Object, arm: bpy.types.Object) -> None:
    head_bone = None
    for name in ("Head", "head", "mixamorig:Head"):
        if name in arm.data.bones:
            head_bone = name
            break
    if head_bone is None:
        for b in arm.data.bones:
            if "head" in b.name.lower():
                head_bone = b.name
                break
    if head_bone is None:
        fail("Head bone not found for hair parenting")
    # Prefer armature weights fully on Head (avoids bone-parent transform blowups).
    hair.vertex_groups.clear()
    vg = hair.vertex_groups.new(name=head_bone)
    vg.add(list(range(len(hair.data.vertices))), 1.0, "REPLACE")
    _ensure_armature_modifier(hair, arm)
    hair.parent = arm
    hair.matrix_parent_inverse = arm.matrix_world.inverted()
    log(f"Hair fully weighted to bone {head_bone}")


def _make_material(name: str, color: tuple[float, float, float, float], roughness: float = 0.55, metallic: float = 0.0) -> bpy.types.Material:
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = roughness
        if "Metallic" in bsdf.inputs:
            bsdf.inputs["Metallic"].default_value = metallic
    return mat


def _assign_materials(mapping: dict[str, bpy.types.Object]) -> None:
    mats = {
        "body": _make_material("MAT_Skin", (0.86, 0.70, 0.60, 1.0), 0.45),
        "hair": _make_material("MAT_Hair", (0.18, 0.10, 0.07, 1.0), 0.35),
        "top": _make_material("MAT_Outfit_Primary", (0.22, 0.38, 0.55, 1.0), 0.6),
        "bottom": _make_material("MAT_Outfit_Secondary", (0.20, 0.22, 0.26, 1.0), 0.7),
        "shoes": _make_material("MAT_Shoes", (0.12, 0.12, 0.12, 1.0), 0.55),
    }
    # Eyes placeholder unused unless separate head mesh
    _make_material("MAT_Eyes", (0.95, 0.95, 0.97, 1.0), 0.2)
    _make_material("MAT_Accessory", (0.75, 0.65, 0.35, 1.0), 0.4, 0.2)
    for key, obj in mapping.items():
        if obj is None or obj.type != "MESH":
            continue
        mat = mats.get(key)
        if mat is None:
            continue
        obj.data.materials.clear()
        obj.data.materials.append(mat)


def _mask_body_under_clothes(body: bpy.types.Object, arm: bpy.types.Object) -> None:
    """
    Keep visible skin: head/neck + full arms/hands.
    Remove covered torso / legs / feet so clothes cannot poke through.
    """
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
            continue  # head / neck
        # Keep full arms (including near-shoulder) — do not strip arm volume.
        if center.z > 0.92 and abs(center.x) > 0.16:
            continue
        delete_faces.append(f)
    bmesh.ops.delete(bm, geom=delete_faces, context="FACES")
    bm.to_mesh(body.data)
    bm.free()
    body.data.update()
    log(f"Masked body under clothes — removed {len(delete_faces)} covered faces")


def _bind_shoes_to_feet(shoes: bpy.types.Object, arm: bpy.types.Object) -> None:
    """
    Rigid per-foot bind for closed Running Shoes.
    Soft skinning from body transfer causes jagged walk spikes on this mesh.
    """
    bone_names = {b.name for b in arm.data.bones}
    left = "foot_l" if "foot_l" in bone_names else "foot_l"
    right = "foot_r" if "foot_r" in bone_names else "foot_r"
    shoes.vertex_groups.clear()
    shoes.vertex_groups.new(name=left)
    shoes.vertex_groups.new(name=right)
    mw = shoes.matrix_world
    for v in shoes.data.vertices:
        wpos = mw @ v.co
        gname = left if wpos.x >= 0.0 else right
        shoes.vertex_groups[gname].add([v.index], 1.0, "REPLACE")
    _ensure_armature_modifier(shoes, arm)
    log("Rigid-bound shoes to foot_l / foot_r")


def _copy_nla_tracks(src_arm: bpy.types.Object, dst_arm: bpy.types.Object) -> list[str]:
    if src_arm.animation_data is None:
        return []
    if dst_arm.animation_data is None:
        dst_arm.animation_data_create()
    # Clear destination NLA
    while dst_arm.animation_data.nla_tracks:
        dst_arm.animation_data.nla_tracks.remove(dst_arm.animation_data.nla_tracks[0])
    names: list[str] = []
    for tr in src_arm.animation_data.nla_tracks:
        new_tr = dst_arm.animation_data.nla_tracks.new(prev=None)
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
    # Also copy active action
    if src_arm.animation_data.action is not None:
        dst_arm.animation_data.action = src_arm.animation_data.action
        if hasattr(src_arm.animation_data, "action_slot") and hasattr(dst_arm.animation_data, "action_slot"):
            try:
                dst_arm.animation_data.action_slot = src_arm.animation_data.action_slot
            except Exception:  # noqa: BLE001
                pass
    return names


def _import_ual_actions(ual_path: Path, arm: bpy.types.Object) -> list[str]:
    log(f"Import UAL animations: {ual_path}")
    before_objs = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(ual_path))
    imported = [o for o in bpy.data.objects if o not in before_objs]
    ual_arms = [o for o in imported if o.type == "ARMATURE"]
    if not ual_arms:
        fail("UAL import produced no armature")
    ual_arm = ual_arms[0]
    track_names = _copy_nla_tracks(ual_arm, arm)
    log(f"Copied NLA tracks to master: {track_names[:40]}")
    # Remove UAL visual clutter (keep actions/NLA on master)
    for obj in imported:
        bpy.data.objects.remove(obj, do_unlink=True)
    if not arm.animation_data:
        arm.animation_data_create()
    return track_names


def _dedupe_exported_glb(glb_path: Path) -> None:
    """Re-open exported GLB and keep a single Armature + unique Proxy meshes."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(glb_path))
    arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    if len(arms) > 1:
        keep = arms[0]
        for arm in arms[1:]:
            log(f"Removing duplicate armature from GLB: {arm.name}")
            for child in list(arm.children_recursive):
                bpy.data.objects.remove(child, do_unlink=True)
            bpy.data.objects.remove(arm, do_unlink=True)
        keep.name = "UAL_MasterArmature"
    seen: set[str] = set()
    keep_names = {"ProxyBody", "ProxyHair", "ProxyTop", "ProxyBottom", "ProxyShoes"}
    for obj in list(bpy.data.objects):
        if obj.type != "MESH":
            continue
        base = obj.name.split(".")[0]
        if base not in keep_names:
            log(f"Removing non-POC mesh from GLB: {obj.name}")
            bpy.data.objects.remove(obj, do_unlink=True)
            continue
        if base in seen:
            log(f"Removing duplicate mesh from GLB: {obj.name}")
            bpy.data.objects.remove(obj, do_unlink=True)
        else:
            seen.add(base)
            obj.name = base
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.data.objects:
        if obj.type in {"ARMATURE", "MESH"}:
            obj.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=str(glb_path),
        use_selection=True,
        export_format="GLB",
        export_animations=True,
        export_skins=True,
        export_morph=False,
        export_apply=False,
        export_extras=False,
    )
    arms_left = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    meshes_left = [o.name for o in bpy.data.objects if o.type == "MESH"]
    log(f"GLB dedupe done arms={len(arms_left)} meshes={meshes_left}")


def _write_selection_md(out: Path) -> None:
    lines = [
        "# POC_SELECTION",
        "",
        f"- Body: `{SELECTION['body']}`",
        f"- Hair: `{SELECTION['hair']}`",
        f"- Top: `{SELECTION['top']}`",
        f"- Bottom: `{SELECTION['bottom']}`",
        f"- Shoes: `{SELECTION['shoes']}`",
        "",
        "## Rationale",
        "",
    ]
    for r in SELECTION["rationale"]:
        lines.append(f"- {r}")
    (out / "POC_SELECTION.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def _write_donor_audit(out: Path, arm: bpy.types.Object, body: bpy.types.Object, donor_path: Path) -> None:
    bones = []

    def walk(bone, depth=0):
        bones.append({"name": bone.name, "parent": bone.parent.name if bone.parent else "", "depth": depth})
        for ch in bone.children:
            walk(ch, depth + 1)

    for root in [b for b in arm.data.bones if b.parent is None]:
        walk(root)
    lines = [
        "# UAL_DONOR_AUDIT",
        "",
        f"- Donor path: `{donor_path}`",
        f"- Armature: `{arm.name}`",
        f"- Body mesh: `{body.name}` verts={len(body.data.vertices)}",
        f"- Bone count: {len(arm.data.bones)}",
        f"- Location: {list(arm.location)}",
        f"- Scale: {list(arm.scale)}",
        f"- Body vertex groups: {len(body.vertex_groups)}",
        "",
        "## Bone hierarchy",
        "",
    ]
    for b in bones:
        lines.append(f"- {'  ' * b['depth']}`{b['name']}` parent=`{b['parent']}`")
    (out / "UAL_DONOR_AUDIT.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    write_json(
        out / "ual_donor_audit.json",
        {
            "donor_path": str(donor_path),
            "armature": arm.name,
            "body": body.name,
            "bones": bones,
            "vertex_groups": [vg.name for vg in body.vertex_groups],
        },
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Build Proxy Girl POC")
    add_common_args(parser)
    args = parser.parse_args(parse_argv_after_double_dash())
    out = ensure_dir(args.output)
    proxy = require_file(args.proxy, "proxy blend")
    donor = require_file(args.donor, "donor gltf")
    ual = require_file(args.ual, "UAL glb")
    _write_selection_md(out)

    _clear_scene()
    arm, donor_body = _import_donor(donor)
    _write_donor_audit(out, arm, donor_body, donor)

    wanted = [SELECTION["body"], SELECTION["hair"], SELECTION["top"], SELECTION["bottom"], SELECTION["shoes"]]
    appended = _append_proxy_objects(proxy, wanted)

    rename_map = {
        SELECTION["body"]: "ProxyBody",
        SELECTION["hair"]: "ProxyHair",
        SELECTION["top"]: "ProxyTop",
        SELECTION["bottom"]: "ProxyBottom",
        SELECTION["shoes"]: "ProxyShoes",
    }
    pieces: dict[str, bpy.types.Object] = {}
    for old, new in rename_map.items():
        obj = appended.get(old)
        if obj is None:
            # try case-insensitive
            for k, v in appended.items():
                if k.lower() == old.lower():
                    obj = v
                    break
        if obj is None:
            fail(f"Missing appended object {old}")
        obj.name = new
        pieces[new] = obj

    # Fit all Proxy parts with shared authored scale + A→T reshape.
    methods = {}
    _fit_proxy_set_to_donor(pieces, donor_body, arm)

    # Weights: pose armature toward Proxy A-pose so donor surface matches spatially,
    # transfer, then clear pose (rest pose / bone names unchanged).
    donor_body.hide_viewport = False
    donor_body.hide_set(False)
    _temp_pose_armature_to_aprox(arm)
    methods["ProxyBody"] = _transfer_weights(donor_body, pieces["ProxyBody"], arm)
    for key in ("ProxyTop", "ProxyBottom"):
        methods[key] = _transfer_weights(pieces["ProxyBody"], pieces[key], arm)
    _sanitize_top_sleeve_weights(pieces["ProxyTop"], arm)
    methods["ProxyTop"] = f"{methods['ProxyTop']}+sleeve_sanitize"
    _bind_shoes_to_feet(pieces["ProxyShoes"], arm)
    methods["ProxyShoes"] = "rigid_foot_bind"
    _clear_armature_pose(arm)
    _mask_body_under_clothes(pieces["ProxyBody"], arm)
    _parent_hair_to_head(pieces["ProxyHair"], arm)

    _assign_materials(
        {
            "body": pieces["ProxyBody"],
            "hair": pieces["ProxyHair"],
            "top": pieces["ProxyTop"],
            "bottom": pieces["ProxyBottom"],
            "shoes": pieces["ProxyShoes"],
        }
    )

    action_names = _import_ual_actions(ual, arm)

    # Reset pose before save so renders start from true rest.
    _clear_armature_pose(arm)
    if arm.animation_data:
        arm.animation_data.action = None
        for tr in arm.animation_data.nla_tracks:
            tr.mute = True

    # Save working blend
    working = out / "ProxyGirl_POC_Working.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(working))
    log(f"Saved working blend: {working}")

    # Export GLB (exclude donor and leftover donor meshes)
    for junk_name in ("DonorBody_PACK021", "Superhero_Female", "Eyebrows", "Eyes", "Icosphere", "Mannequin"):
        junk = bpy.data.objects.get(junk_name)
        if junk:
            junk.hide_render = True
            junk.hide_viewport = True
            junk.select_set(False)
    export_path = out / "GirlProxyPOC.glb"
    bpy.ops.object.select_all(action="DESELECT")
    export_objs = [arm] + [pieces[k] for k in pieces]
    for o in export_objs:
        o.select_set(True)
        o.hide_set(False)
        o.hide_render = False
    bpy.context.view_layer.objects.active = arm
    bpy.ops.export_scene.gltf(
        filepath=str(export_path),
        use_selection=True,
        export_format="GLB",
        export_animations=True,
        export_skins=True,
        export_morph=False,
        export_apply=False,
        export_extras=False,
    )
    log(f"Exported {export_path}")

    report = {
        "selection": SELECTION,
        "armature": arm.name,
        "donor_body": donor_body.name,
        "weight_methods": methods,
        "ual_actions": action_names,
        "working_blend": str(working),
        "glb": str(export_path),
        "blender": bpy.app.version_string,
    }
    write_json(out / "build_report.json", report)
    _dedupe_exported_glb(export_path)
    log("Build complete")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        fail(f"Unhandled build error: {exc}")
