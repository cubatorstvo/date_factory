# VISUAL BOOTSTRAP CORRECTIVE — Final Report

**Date:** 2026-08-09  
**Orchestrator verdict:** **READY**  
**Independent QA:** `docs/agent/qa/VISUAL_BOOTSTRAP_CORRECTIVE_QA.md` on review branch — READY after character attach fix  
**Source (main):** `b59c3c9`  
**Review branch:** `visual-review/corrective-20260809` @ `05c2f0a`

---

## 1. CITY DONOR PARITY

- Wrapper brightening `WorldEnvironment` + `Sun` removed; `Geometry/DonorCity` owns night env.
- Active: donor bg `(0.04,0.05,0.1)`, ambient `0.5`, ACES/glow; `NightKey` `0.48`, `NightFill` `0.18`.
- Cyan transition BoxMeshes / Label3D hidden; travel Areas kept at façades; Lab/Production got `Door_2` visuals; PublicCityGate red box → bollards.
- Megakit red trim left as pack/donor-native (not wrapper wash).

## 2. APARTMENT

Debug Label3D removed from production render (`ДЕНЬ`, `Стол для свидания`, `Самооценка`, flavor boxes).

| Interaction | Real object |
|---|---|
| DayAdvance | `Furniture/Bed` (Bed_Single) |
| DateVenue | `Furniture/DiningTable` (Table_RoundSmall2) |
| ProgressionSelfAssessment | `Furniture/Wardrobe` (Drawer_4) — no bathroom mirror in art |
| Phone | `Furniture/NightStand` |
| FlavorMirror / Wardrobe / Fridge / Window / Chair | Bookshelf / Wardrobe / Fridge / Window / DiningChairSouth |
| ToCity | Exit door |

Lighting: donor evening Environment restored on art; wrapper Sun off / env matched.

## 3. CAFE

- Donor purple evening restored (exposure `1.12`, volumetric fog, WarmFill + omnis).
- Wrapper gray ambient + Sun removed.
- PACK_019 `Girl_Casual` / `Casual.gltf` stripped from `restaurant.tscn`.
- DateVenue / Flavor Areas remain on sushi table/counter furniture (meshes/labels hidden).

## 4. INTERACTIVE PLACEHOLDER REPLACEMENT

| location | old placeholder | replacement asset | interaction node | new parent/object |
|---|---|---|---|---|
| city | cyan Transition Mesh/Labels | façade doors / `Door_2` / BusStop; meshes hidden | `Transitions/To*` | same Areas at POIs |
| city | Flavor beige Mesh+Label | hidden or `Prop_Planter_Single` | `Interactables/Flavor*` | same Areas |
| city | PublicCityGate red BoxMesh | `Prop_Bollard` ×5 | gate BarrierBody | `FeatureGates/PublicCityGate` |
| apartment | DayAdvance Label «ДЕНЬ» | Bed_Single | `DayAdvance` | at bed |
| apartment | DateVenue Label | Table_RoundSmall2 | `DateVenue` | at table |
| apartment | SelfAssessment Label | Wardrobe/Drawer_4 | `ProgressionSelfAssessment` | at wardrobe |
| apartment | Flavor* boxes | donor furniture | Flavor* | at props |
| cafe | PACK_019 DateGirl | removed (production spawn) | — | — |
| cafe | DateVenue/Flavor debug | sushi furniture (meshes hidden) | DateVenue / Flavor* | tables/counter |
| mine | Title «ЗАРПЛАТНАЯ ЖИЛА» + boxes | SalaryMachine + SalaryScreen | `SalaryStation` | at machine |
| lab | Machine/Terminal Labels + boxes | Prop_SatelliteDish / Prop_Desk_L + screens | FirstCloneMachine / CloneTerminal | under Areas |
| lab | Ceiling BoxMesh FOV slab | hidden; walls raised | — | — |
| late | cyan terminal/event boxes + Labels | Prop_Desk + Kenney screens / crates | GlobalExpansionTerminal / LateEvent* / FlavorWorldMap | under Areas |

No silently floating invisible interactions introduced by this pass (Areas retained with CollisionShape3D and physical anchors).

## 5. CHARACTER BASES

```text
male base path:   res://assets/characters/hero_base/meshes/bodies/Superhero_Male_FullBody.gltf
female base path: res://assets/characters/hero_base/meshes/bodies/Superhero_Female_FullBody.gltf
```

Wrappers: `characters/male/male_base_visual.tscn`, `characters/female/female_base_visual.tscn`  
Controller: `characters/framework/character_variant_controller.gd`  
Female anim: UAL (`animation_female_base` → `DF_UAL_Aliases`).

## 6. PACK_019 REMOVAL

```text
source removed YES
runtime refs 0 YES
unused wrappers removed YES (production path uses PACK_021 bases; thin female_*_visual retarget to female base)
```

Docs: `docs/THIRD_PARTY_ASSETS.md` marks PACK_019 not used in production.

## 7. MODULAR VARIANTS

```text
hair: 5 styles (+ 5 colors via material: black/brown/blond/red/unusual)
tops: 4
bottoms: 3
shoes: 2
head accessories: 3 (none/glasses/hat)
neck accessories: 2 + none
hand accessories: 2 + none
colors: hair 5; cloth palette via CLOTH_COLOR_MAP
```

Temporary primitive placeholders on `BoneAttachment3D` (Head / UpperChest / Hips / LeftFoot / Neck / LeftHand). Attach fix: external_skeleton `../Body/Armature/Skeleton3D`.

## 8. MINE/LAB/LATE

- **Mine:** floating salary title hidden; machine/screen remain physical anchors; Kenney PackVisuals kept.
- **Lab:** debug labels hidden; ceiling slab hidden; clone machine/terminal Areas parent PACK_015 props; dating booth shells kept (no PACK_013).
- **Late:** terminal/events/flavor Areas parent desk/screen/crate props; debug labels/geo signs hidden; UpgradeVisuals boxes left (non-interactive scope).

## 9. LICENSE

PACK_016 docs updated **YES** — Quaternius CC0, official source `https://quaternius.com/packs/sushirestaurantkit.html`, cafe donor dependency only (`docs/ASSET_LICENSES.md`).

## 10. REGRESSION

```text
15/15 RC headless exit 0 (character_presentation 902; content 649; dating 270; clone/late/final/first_clone/salary/save/rivals/girls/… ALL PASS)
donor refs 0
PACK019 refs 0
```

Logs: `tmp/vc_rc/suite_summary.txt`

## 11. REVIEW

```text
branch: visual-review/corrective-20260809
SHA:    05c2f0a
path:   _review/visual_corrective/
screenshot count: 31
```

Source commits on main: `d9fa832` (corrective), `b59c3c9` (bone-attach fix).

---

**STOP** — no further art-polish in this pass.
