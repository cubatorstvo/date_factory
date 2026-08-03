#!/usr/bin/env python3
"""Rewrite character prefabs to instance imported glTF + AnimationPlayer hooks."""

from pathlib import Path

PROJECT = Path(r"C:\Users\User\Documents\GodotProjects\date_factory")

PREFAB_SPECS = [
    {
        "path": PROJECT / "assets/characters/hero_base/prefabs/Hero.tscn",
        "name": "Hero",
        "mesh": "res://assets/characters/hero_base/meshes/bodies/Superhero_Male_FullBody.gltf",
        "anim": "res://assets/animation/universal_library/source/UAL1_Standard.glb",
    },
    {
        "path": PROJECT / "assets/characters/hero_base/prefabs/Clone.tscn",
        "name": "Clone",
        "mesh": "res://assets/characters/hero_base/meshes/bodies/Superhero_Male_FullBody.gltf",
        "anim": "res://assets/animation/universal_library/source/UAL1_Standard.glb",
    },
    {
        "path": PROJECT / "assets/characters/women_modular/prefabs/Girl_Casual.tscn",
        "name": "Girl_Casual",
        "mesh": "res://assets/characters/women_modular/meshes/individuals/Casual.gltf",
        "anim": "res://assets/animation/universal_library/source/UAL1_Standard.glb",
    },
    {
        "path": PROJECT / "assets/characters/women_modular/prefabs/Girl_Formal.tscn",
        "name": "Girl_Formal",
        "mesh": "res://assets/characters/women_modular/meshes/individuals/Formal.gltf",
        "anim": "res://assets/animation/universal_library/source/UAL1_Standard.glb",
    },
    {
        "path": PROJECT / "assets/characters/women_modular/prefabs/Girl_Worker.tscn",
        "name": "Girl_Worker",
        "mesh": "res://assets/characters/women_modular/meshes/individuals/Worker.gltf",
        "anim": "res://assets/animation/universal_library/source/UAL1_Standard.glb",
    },
    {
        "path": PROJECT / "assets/characters/women_modular/prefabs/Manager_Suit.tscn",
        "name": "Manager_Suit",
        "mesh": "res://assets/characters/women_modular/meshes/individuals/Suit.gltf",
        "anim": "res://assets/animation/universal_library/source/UAL1_Standard.glb",
    },
]


def write_prefab(spec: dict) -> None:
    # Instanced character mesh + hidden anim library source + AnimationPlayer.
    # Clip remapping (idle/walk/run/sit/stand/gesture/react) documented in UAL_CLIP_MAP.json.
    content = f"""[gd_scene load_steps=4 format=3]

[ext_resource type="PackedScene" path="{spec['mesh']}" id="1_mesh"]
[ext_resource type="PackedScene" path="{spec['anim']}" id="2_anim"]

[sub_resource type="CapsuleShape3D" id="Shape_1"]
radius = 0.3
height = 1.75

[node name="{spec['name']}" type="CharacterBody3D"]
collision_layer = 2
metadata/_df_anim_aliases = PackedStringArray("idle", "walk", "run", "sit", "stand", "gesture", "react")
metadata/_df_anim_source = "{spec['anim']}"

[node name="Visual" parent="." instance=ExtResource("1_mesh")]

[node name="Collision" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.875, 0)
shape = SubResource("Shape_1")

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]

[node name="UAL_LibrarySource" parent="." instance=ExtResource("2_anim")]
visible = false
process_mode = 4
"""
    spec["path"].parent.mkdir(parents=True, exist_ok=True)
    spec["path"].write_text(content, encoding="utf-8")
    print("wrote", spec["path"].relative_to(PROJECT))


def enhance_test_scenes_with_kits() -> None:
    """Append a few real kit instances into blockout scenes via companion kit nodes file."""
    # City street: instance a few downtown pieces if available
    city_meshes = sorted((PROJECT / "assets/environment/city/downtown_megakit/meshes").glob("*.gltf"))
    picks = []
    for stem in ["Brick_Plain_1", "Brick_Inset_Window", "Concrete_Road", "Road", "Sidewalk", "Door"]:
        for m in city_meshes:
            if stem.lower() in m.stem.lower():
                picks.append(m)
                break
    picks = picks[:6]
    if not picks:
        picks = city_meshes[:6]

    out = PROJECT / "scenes/art/city/City_Street_KitInstances.tscn"
    lines = [f"[gd_scene load_steps={len(picks)+1} format=3]\n\n"]
    for i, m in enumerate(picks, 1):
        res = "res://" + str(m.relative_to(PROJECT)).replace("\\", "/")
        lines.append(f'[ext_resource type="PackedScene" path="{res}" id="{i}"]\n')
    lines.append('\n[node name="City_Street_KitInstances" type="Node3D"]\n')
    for i, m in enumerate(picks):
        x = -6 + i * 2.5
        lines.append(f'\n[node name="{m.stem}" parent="." instance=ExtResource("{i+1}")]\n')
        lines.append(f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, 0, -6)\n")
    out.write_text("".join(lines), encoding="utf-8")
    print("wrote", out.relative_to(PROJECT))

    # Factory kit slice
    fac = sorted((PROJECT / "assets/environment/factory/kenney_factory/meshes").glob("*.glb"))
    want = ["conveyor-bars", "machine", "pipe", "tank", "box-large", "catwalk-straight"]
    fpicks = []
    for w in want:
        for m in fac:
            if w in m.stem.lower():
                fpicks.append(m)
                break
    fpicks = (fpicks or fac)[:8]
    outf = PROJECT / "scenes/art/factory/Date_Factory_KitInstances.tscn"
    lines = [f"[gd_scene load_steps={len(fpicks)+1} format=3]\n\n"]
    for i, m in enumerate(fpicks, 1):
        res = "res://" + str(m.relative_to(PROJECT)).replace("\\", "/")
        lines.append(f'[ext_resource type="PackedScene" path="{res}" id="{i}"]\n')
    lines.append('\n[node name="Date_Factory_KitInstances" type="Node3D"]\n')
    for i, m in enumerate(fpicks):
        x = -4 + i * 1.5
        lines.append(f'\n[node name="{m.stem}" parent="." instance=ExtResource("{i+1}")]\n')
        lines.append(f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, 0, 0)\n")
    outf.write_text("".join(lines), encoding="utf-8")
    print("wrote", outf.relative_to(PROJECT))


if __name__ == "__main__":
    for spec in PREFAB_SPECS:
        write_prefab(spec)
    enhance_test_scenes_with_kits()
