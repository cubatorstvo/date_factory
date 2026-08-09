# VISUAL ART PASS 01 — Final Report

**Date:** 2026-08-09  
**Orchestrator verdict:** **READY**  
**Independent QA:** `docs/agent/qa/VISUAL_ART_PASS_01_QA.md` on review branch — READY after fix3  
**Main:** `7ee5fde`  
**Review:** `visual-review/art-pass-01-20260809` @ `04cac77`

---

## CHARACTER HAIR

```text
primitive hair removed: YES
```

Base dir: `res://assets/characters/hero_base/meshes/hairstyles/Origin at 0/glTF (Godot)/`

```text
male mapping:
0 bald (Hair_00 empty)
1 res://assets/characters/hero_base/meshes/hairstyles/Origin at 0/glTF (Godot)/Hair_Buzzed.gltf
2 res://assets/characters/hero_base/meshes/hairstyles/Origin at 0/glTF (Godot)/Hair_SimpleParted.gltf
3 res://assets/characters/hero_base/meshes/hairstyles/Origin at 0/glTF (Godot)/Hair_Long.gltf
4 res://assets/characters/hero_base/meshes/hairstyles/Origin at 0/glTF (Godot)/Hair_Buns.gltf

female mapping:
0 res://assets/characters/hero_base/meshes/hairstyles/Origin at 0/glTF (Godot)/Hair_BuzzedFemale.gltf
1 res://assets/characters/hero_base/meshes/hairstyles/Origin at 0/glTF (Godot)/Hair_SimpleParted.gltf
2 res://assets/characters/hero_base/meshes/hairstyles/Origin at 0/glTF (Godot)/Hair_Long.gltf
3 res://assets/characters/hero_base/meshes/hairstyles/Origin at 0/glTF (Godot)/Hair_Buns.gltf
4 bald (Hair_04 empty)
```

`Hair_Beard` unused. Per-instance hair color overrides. Bone: Head via `../Body/Armature/Skeleton3D`.

## CHARACTER CLOTHING

- **Tops:** `TopRoot` → `Chest`; `Top_00`..`Top_03` thin front shells (short-sleeve / vest / jacket / hoodie silhouettes). Sleeve pieces available; walk keeps shell on chest.
- **Bottoms:** `BottomRoot` → `Hips`; `Bottom_00` shorts (both thighs), `Bottom_01` pants both legs, `Bottom_02` skirt-like.
- **Shoes:** `ShoesRoot` with `LeftFootAttachment` + `RightFootAttachment`; variants `Shoes_00` / `Shoes_01` pairs; flat sole boxes under feet.
- **Accessories:** Head (None/Glasses/Hat), Neck (None/01/02), Hand (None/01/02) — cleaned scale/placement.

```text
one-foot footwear bug fixed: YES
```

Temporary BoxMesh clothing remains intentionally primitive (TZ), but no longer giant hollow frames / ankle IK cubes / walk back-plates.

## CITY POI AUDIT

| scene | lot size | old exterior | action | new building | status |
|---|---|---|---|---|---|
| PlayerHome | 9×8 | Building_Small_1 | keep | Small_1 | PRESERVED_REAL |
| CafeTwoHearts | 10×9 | Building_Medium_2_001 | keep | Medium_2_001 | PRESERVED_REAL |
| ParkRestaurant | 10×9 | Building_Medium_2_001 | keep | Medium_2_001 | PRESERVED_REAL |
| Cinema | 14×11 | Building_Large_2 | keep | Large_2 | PRESERVED_REAL |
| AgencyOffice | 10×9 | ProxyBody | replace | Medium_2_001 | REPLACED_MEDIUM |
| Gym | 9×8 | ProxyBody | replace | Medium_2_001 | REPLACED_MEDIUM |
| Arcade | 8×8 | ProxyBody | replace | Small_1 | REPLACED_SMALL |
| Bar | 7×7 | ProxyBody | replace | Small_1 | REPLACED_SMALL |
| BarberShop | 6×7 | ProxyBody | replace | Small_1 | REPLACED_SMALL |
| Bookstore | 6×7 | ProxyBody | replace | Small_1 | REPLACED_SMALL |
| HomewareShop | 6×7 | ProxyBody | replace | Small_1 | REPLACED_SMALL |
| InternetCafe | 7×7 | ProxyBody | replace | Small_1 | REPLACED_SMALL |
| PhotoStudio | 6×7 | ProxyBody | replace | Small_1 | REPLACED_SMALL |
| FashionPairJewelryClothing | 12×7.5 | ProxyBody | replace | Large_2 | REPLACED_LARGE |
| RetailPairFlowerGift | 12×7.5 | ProxyBody | replace | Large_2 | REPLACED_LARGE |

`READY_BUILDING_FIT_FAILED`: none.

## CITY DEBUG VISUALS

```text
LotBounds visible in production: 0
```

(`CityPOIBuilding` hides LotBounds/ReservedLot/DebugLot at runtime.)

## NPC PRESENTATION

```text
city spawn exclusion: 2.5m
cafe ordinary visual cap: 4
date exclusion: 2.2m
```

Implemented via `world/npc_presentation_rules.gd` on city/cafe `NpcSpawns`. Content IDs unchanged.

## REGRESSION

```text
14/14 required PASS
donor refs: 0
PACK019 refs: 0
```

Includes character_presentation ALL PASS (1104), npc_presentation ALL PASS (25), dating/content/save/clone/late/final/salary/rivals/girls.

Apartment / mine / lab / late: no art changes this pass (regression shots only).

## REVIEW

```text
main commit: 7ee5fde
review branch: visual-review/art-pass-01-20260809
review SHA: 04cac77
screenshot path: _review/art_pass_01/
screenshot count: 25
```

---

**STOP** — no Lab/Late art-polish in this pass.
