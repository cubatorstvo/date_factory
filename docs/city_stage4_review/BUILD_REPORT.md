# BUILD_REPORT — City Stage 4

Status: `IMPLEMENTED — MANUAL CHECK REQUIRED`

## What changed

Full Stage-4 rebuild of `city.tscn` from `tools/date_factory_city_stage4_build_manifest.json`:

- roads / plazas / park path / pond under `GeneratedCity`
- managed POI buildings + amenity prefabs at manifest transforms
- markers, street lamps, background buildings, vegetation
- translucent physical district gates (`ParkGate`, `AgencyGate`, `AgencyGateLeisure`)
- art-backed interactions resolve via Marker3D / node anchors
- NPC spots/waypoints loaded from manifest; filtered by unlocked districts
- cool navy/violet night environment + warm spherical lamps

## Changed / created files

### Created

- `scenes/art/city/backups/city_before_stage4.tscn`
- `scenes/art/city/prefabs/PlayerHomeFacade.tscn`
- `scenes/art/city/prefabs/CafeTwoHearts.tscn`
- `scenes/art/city/prefabs/BookstoreFacade.tscn`
- `scenes/art/city/prefabs/DistrictGate.tscn`
- `scenes/art/city/prefabs/StreetLampRomance.tscn`
- `scenes/art/city/prefabs/district_gate.gd`
- `tools/date_factory_city_stage4_build_manifest.json`
- `tools/build_city_stage4.gd`
- `tools/validate_city_stage4.gd`
- `tools/capture_city_stage4_review.gd`
- `docs/city_stage4_review/*` (screenshots + reports)

### Modified

- `scenes/world/city/city.tscn` (full Stage-4 rebuild)
- `scenes/world/city_builder.gd` (no legacy greybox/interacts; manifest nav)
- `scenes/world/complex_world.gd` (marker interacts; `district_gate` group sync; nav filter)
- `docs/city_handoff/copies/**/*.gd` (`class_name` stripped from copies to stop global class clashes)

## Prefabs created

| Prefab | Notes |
|---|---|
| PlayerHomeFacade | Building_Small_1, anchors at +Z street |
| CafeTwoHearts | Building_Medium_2_001, warm light, facade sign |
| BookstoreFacade | Building_Small_1 + shelves/sign |
| DistrictGate | translucent emissive barrier + collision + InteractionArea |
| StreetLampRomance | slim pole + warm sphere + OmniLight3D |

## Headless validation

Command:

`Godot_v4.7.1-stable_win64.exe --headless --path . --script res://tools/validate_city_stage4.gd`

Result: `VALIDATE_CITY_STAGE4_PASS`

Checks covered:

- all POI / markers / gates present
- transforms within 0.02
- no missing required prefab resources
- no duplicate managed node names
- 3 gates with correct `district_id`
- agency gates hide together
- collision footprints of POI buildings do not overlap
- no Interactable nodes inside `city.tscn`
- action IDs preserved in manifest coverage
- pond collision present

## Screenshots

Folder: `docs/city_stage4_review/`

- `01_topdown_locked.png`
- `02_topdown_all_open.png`
- `03_spawn_view.png`
- `04_route_home_to_cafe.png` … `12_route_agency_lane.png`
- route / gate frames including both agency gates and park→restaurant view

Capture note: real GPU capture via minimized window (`-s` without `--headless`). Dummy headless renderer returns null images.

## Manifest deviations / technical contradictions

1. **GodotIQ MCP unavailable** (tool calls timed out). Build/validation used existing headless SceneTree tool pattern instead of bridge ops.
2. **`Architecture` children cleared** while keeping the node. Compact-city roads/ground would overlap Stage-4 `GeneratedCity`; floor collider retained under `Architecture/PerimeterCollision`.
3. **Handoff copies `class_name` removed** under `docs/city_handoff/copies/**` so Godot would compile (`CityAPI` / `Interactable` clashes). Gameplay scripts under `modules/` / `scenes/world/` unchanged in API.
4. **AABB validation uses Collision footprint**, not raw mesh AABB (imported meshes + lights inflate false overlaps). Game meaning preserved: no overlapping POI collision boxes.
5. **Coordinates not altered** from manifest. Runtime still applies CityVisual mount offset `(-30,0,0)` and `CITY_WORLD_SCALE=1.5` exactly once in `complex_world.gd`.

## Known visual / manual risks

- Top-down orthographic frames flatten street tiles; prefer eye-level route shots for facade QA.
- Cafe / restaurant still reuse sushi kit sign mesh plus authored `TWO HEARTS` board.
- Player walkability through full unlocked loop, save/load of district states, and prompt placement at facades need manual playcheck.
- NPC pathing relies on waypoint filtering + physical gates/pond collision; no navmesh bake in this stage.

## Not automatically verified

- Full player walk loop home → central → park → leisure → agency → central
- District unlock persistence across save/load
- Visual material polish / missing textures at eye level
- Balance of lamp/POI bloom in final game lighting stack (city WorldEnvironment is nulled when mounted under complex_world ambient)
