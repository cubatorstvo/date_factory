"""
Audit OverScore Proxy 1.5 without modifying the source blend.
Writes PROXY_AUDIT.md, proxy_inventory.json, proxy_inventory.csv and contact sheets.
"""
from __future__ import annotations

import argparse
import csv
import math
import sys
from pathlib import Path

# Allow importing sibling module when run via Blender --python
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
    require_file,
    write_json,
)


def _bbox_world(obj: bpy.types.Object) -> dict:
    corners = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    xs = [c.x for c in corners]
    ys = [c.y for c in corners]
    zs = [c.z for c in corners]
    return {
        "min": [min(xs), min(ys), min(zs)],
        "max": [max(xs), max(ys), max(zs)],
        "size": [max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)],
        "center": [(min(xs) + max(xs)) * 0.5, (min(ys) + max(ys)) * 0.5, (min(zs) + max(zs)) * 0.5],
    }


def _guess_category(obj: bpy.types.Object, collections: list[str], bbox: dict) -> str:
    name = obj.name.lower()
    coll = " ".join(collections).lower()
    blob = f"{name} {coll}"
    size = bbox["size"]
    height = size[2]
    width = max(size[0], size[1])
    center_z = bbox["center"][2]

    def has(*keys: str) -> bool:
        return any(k in blob for k in keys)

    if obj.type != "MESH":
        return "unknown"
    if has("hair", "bun", "ponytail", "braid", "fringe", "bang"):
        return "hair"
    if has("shoe", "boot", "sneaker", "heel", "sandal", "footwear"):
        return "shoes"
    if has("body", "base", "nude", "skin", "figure", "proxy_body", "female_body"):
        return "body"
    if has("head") and height < 0.45:
        return "head"
    if has("dress", "gown", "jumpsuit", "romper", "outfit", "suit", "overall"):
        return "full_outfit"
    if has("top", "shirt", "blouse", "tee", "hoodie", "jacket", "sweater", "crop", "tank"):
        return "top"
    if has("bottom", "pant", "jean", "skirt", "short", "trouser", "legging"):
        return "bottom"
    if has("bag", "glass", "hat", "earring", "necklace", "watch", "ring", "accessory", "belt"):
        return "accessory"

    # Heuristics by proportions / height band
    if height > 1.4 and width < 0.9 and center_z > 0.6:
        if "cloth" in blob or "wear" in blob:
            return "full_outfit"
        return "body"
    if 0.35 < height < 0.95 and center_z > 1.2 and width < 0.55:
        return "hair"
    if height < 0.35 and center_z < 0.25:
        return "shoes"
    if 0.4 < height < 0.9 and 0.7 < center_z < 1.35:
        return "top"
    if 0.5 < height < 1.1 and center_z < 0.85:
        return "bottom"
    return "unknown"


def _mesh_stats(obj: bpy.types.Object) -> dict:
    mesh = obj.data
    return {
        "mesh_data": mesh.name if mesh else "",
        "vertices": len(mesh.vertices) if mesh else 0,
        "polygons": len(mesh.polygons) if mesh else 0,
        "materials": [slot.material.name if slot.material else "" for slot in obj.material_slots],
        "shape_keys": (
            [kb.name for kb in mesh.shape_keys.key_blocks] if mesh and mesh.shape_keys else []
        ),
        "vertex_groups": [vg.name for vg in obj.vertex_groups],
        "modifiers": [mod.type for mod in obj.modifiers],
    }


def _object_record(obj: bpy.types.Object) -> dict:
    collections = [c.name for c in obj.users_collection]
    bbox = _bbox_world(obj) if obj.type == "MESH" else {"min": [], "max": [], "size": [], "center": []}
    rec = {
        "name": obj.name,
        "type": obj.type,
        "collections": collections,
        "parent": obj.parent.name if obj.parent else "",
        "location": list(obj.location),
        "rotation_euler": list(obj.rotation_euler),
        "scale": list(obj.scale),
        "bbox": bbox,
        "category": _guess_category(obj, collections, bbox) if obj.type == "MESH" else "unknown",
        "hide_viewport": bool(obj.hide_viewport),
        "hide_render": bool(obj.hide_render),
    }
    if obj.type == "MESH":
        rec.update(_mesh_stats(obj))
    return rec


def _write_csv(path: Path, rows: list[dict]) -> None:
    fields = [
        "name",
        "type",
        "category",
        "collections",
        "parent",
        "vertices",
        "polygons",
        "materials",
        "shape_keys",
        "vertex_groups",
        "modifiers",
        "location",
        "scale",
        "bbox_size",
    ]
    ensure_dir(path.parent)
    with path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow(
                {
                    "name": row.get("name", ""),
                    "type": row.get("type", ""),
                    "category": row.get("category", ""),
                    "collections": "|".join(row.get("collections", [])),
                    "parent": row.get("parent", ""),
                    "vertices": row.get("vertices", ""),
                    "polygons": row.get("polygons", ""),
                    "materials": "|".join(row.get("materials", [])),
                    "shape_keys": "|".join(row.get("shape_keys", [])),
                    "vertex_groups": "|".join(row.get("vertex_groups", [])),
                    "modifiers": "|".join(row.get("modifiers", [])),
                    "location": row.get("location", ""),
                    "scale": row.get("scale", ""),
                    "bbox_size": row.get("bbox", {}).get("size", ""),
                }
            )


def _render_contact_sheet(objects: list[bpy.types.Object], out_path: Path, title: str) -> None:
    if not objects:
        log(f"Contact sheet skipped (empty): {title}")
        return
    # Isolate visibility
    for obj in bpy.data.objects:
        obj.hide_render = True
        obj.hide_viewport = True
    for obj in objects[:24]:
        obj.hide_render = False
        obj.hide_viewport = False

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items.keys() else "BLENDER_WORKBENCH"
    # Blender 5 may use EEVEE_NEXT
    engines = {item.identifier for item in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items}
    if "BLENDER_EEVEE_NEXT" in engines:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    elif "BLENDER_EEVEE" in engines:
        scene.render.engine = "BLENDER_EEVEE"
    else:
        scene.render.engine = "BLENDER_WORKBENCH"

    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.render.filepath = str(out_path)

    # Camera
    cam_data = bpy.data.cameras.new("AuditCam")
    cam = bpy.data.objects.new("AuditCam", cam_data)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    # Frame selected objects roughly
    centers = []
    for obj in objects[:24]:
        if obj.type == "MESH":
            bb = _bbox_world(obj)
            centers.append(Vector(bb["center"]))
    if centers:
        mid = sum(centers, Vector()) / len(centers)
        cam.location = (mid.x, mid.y - 3.5, mid.z + 1.2)
        direction = mid - cam.location
        cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    else:
        cam.location = (0, -4, 1.5)

    # Light
    light_data = bpy.data.lights.new("AuditLight", type="AREA")
    light_data.energy = 400
    light = bpy.data.objects.new("AuditLight", light_data)
    bpy.context.collection.objects.link(light)
    light.location = (2, -2, 3)

    ensure_dir(out_path.parent)
    bpy.ops.render.render(write_still=True)
    log(f"Contact sheet written: {out_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Audit Proxy 1.5 blend")
    add_common_args(parser)
    args = parser.parse_args(parse_argv_after_double_dash())
    proxy = require_file(args.proxy, "proxy blend")
    out = ensure_dir(args.output)
    sheets = ensure_dir(out / "contact_sheets")

    log(f"Blender {bpy.app.version_string}")
    log(f"Opening proxy (read-only workflow): {proxy}")
    bpy.ops.wm.open_mainfile(filepath=str(proxy))

    collections = sorted(c.name for c in bpy.data.collections)
    records = [_object_record(obj) for obj in sorted(bpy.data.objects, key=lambda o: o.name)]
    mesh_records = [r for r in records if r["type"] == "MESH"]

    by_cat: dict[str, list[dict]] = {}
    for rec in mesh_records:
        by_cat.setdefault(rec["category"], []).append(rec)

    inventory = {
        "blender_version": bpy.app.version_string,
        "proxy_path": str(proxy),
        "collections": collections,
        "object_count": len(records),
        "mesh_count": len(mesh_records),
        "category_counts": {k: len(v) for k, v in sorted(by_cat.items())},
        "objects": records,
    }
    write_json(out / "proxy_inventory.json", inventory)
    _write_csv(out / "proxy_inventory.csv", records)

    # Contact sheets by category
    name_to_obj = {o.name: o for o in bpy.data.objects}
    for cat in ("body", "hair", "full_outfit", "top", "bottom", "shoes", "accessory"):
        objs = [name_to_obj[r["name"]] for r in by_cat.get(cat, []) if r["name"] in name_to_obj]
        # Prefer larger / more complete looking first
        objs.sort(key=lambda o: len(o.data.vertices) if o.type == "MESH" else 0, reverse=True)
        try:
            _render_contact_sheet(objs[:16], sheets / f"{cat}_sheet.png", cat)
        except Exception as exc:  # noqa: BLE001
            log(f"Contact sheet failed for {cat}: {exc}")

    # Markdown audit
    lines = [
        "# PROXY AUDIT",
        "",
        f"- Blender: `{bpy.app.version_string}`",
        f"- Source (unchanged): `{proxy}`",
        f"- Objects: **{len(records)}** (meshes: **{len(mesh_records)}**)",
        f"- Collections: {', '.join(f'`{c}`' for c in collections)}",
        "",
        "## Category counts",
        "",
    ]
    for cat, count in sorted(inventory["category_counts"].items(), key=lambda kv: (-kv[1], kv[0])):
        lines.append(f"- `{cat}`: {count}")
    lines += ["", "## Top mesh candidates by category", ""]
    for cat in ("body", "hair", "full_outfit", "top", "bottom", "shoes", "accessory", "unknown"):
        rows = sorted(by_cat.get(cat, []), key=lambda r: r.get("vertices", 0), reverse=True)[:12]
        lines.append(f"### {cat}")
        if not rows:
            lines.append("- _(none)_")
            continue
        for r in rows:
            lines.append(
                f"- `{r['name']}` verts={r.get('vertices', 0)} polys={r.get('polygons', 0)} "
                f"coll={r.get('collections')} size={r.get('bbox', {}).get('size')}"
            )
        lines.append("")

    (out / "PROXY_AUDIT.md").write_text("\n".join(lines), encoding="utf-8")
    log(f"Wrote {out / 'PROXY_AUDIT.md'}")
    log("Audit complete")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        fail(f"Unhandled audit error: {exc}")
