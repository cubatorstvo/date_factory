# Prototype City — Validation Report

## Review package

All files are under `res://docs/prototype_city_review/`. PNG hashes are unique (not duplicate camera dumps).

| File | Camera intent | Notes after opening the image |
|---|---|---|
| `01_topdown_all_zones.png` | Y=52 over origin | Full donor-scale footprint: main street, park grass, agency row, sidewalks |
| `02_topdown_stage1.png` | Over east street | Home / cafe / shop row along the road |
| `03_topdown_stage2.png` | Over park | Green park, pond, leisure POIs |
| `04_topdown_stage3.png` | Over agency row | Cooler/taller masses, west street |
| `05_spawn_view.png` | Street near (32.4, 2.5, 9) | Primitive facades, door, windows, sidewalk |
| `06_stage1_route.png` | Looking west along Stage 1 | Street corridor |
| `07_stage2_gate.png` | Toward ParkGate from south | Street-level; nearby volumes occlude the thin barrier somewhat |
| `08_stage2_route.png` | Into the park | Duck feeding / park volumes |
| `09_stage3_gate.png` | Toward AgencyGate | Street-level west of origin |
| `10_stage3_route.png` | Along agency row | Office / photo / barber masses |
| `11_full_city_open.png` | Isometric (28, 36, 40) | Whole layout + white DistrictGate planes |

Editor captures are the visual source of truth for layout. In-game viewport capture via the runtime bridge timed out (see below).

## Checklist

### 1. Spawn

Hub `PlayerSpawns/spawn_default` is `(29.2, 0.05, 9)` — donor `PlayerSpawn`.  
`verify_project_runs` on `city_hub.tscn`: **PASS**, play attached, **0** script / runtime errors.

### 2–3. Stage 1 route and POI

Stage 1 instances at donor coordinates. Interactions live inside PackedScenes:

- `go_home`, `sit_cafe`, `open_flower_shop`, `open_gift_shop`, `open_jewelry_shop`, `open_clothing_shop`, `open_homeware_shop`, `city_cafe_job` (+ `city_cafe_scroll`, `city_coffee`), `city_rest` (MainBench)

Hub travel: `ToApartment`, `ToCafe` on donor entrance markers.

### 4–6. Stage 2 closed / open / route

`ParkGate` at `(0, 0, 7.2)`, `district_id=park_leisure`.  
Unlock: `Story.is_feature_unlocked(PUBLIC_CITY_ACCESS)` when `GameState` stage ≥ `STAGE_2`.  
`district_gate_sync.gd` calls `DistrictGate.set_unlocked()`.

Hub also has `PublicCityGate` at the same origin (WorldFeatureGate, bollards hidden). Both should open with public city access.

Stage 2 POI `action_id`s preserved: `open_bookstore`, `city_workout` / `city_gym_pass`, `sit_cinema`, `open_arcade` / `sit_arcade`, `city_bar_drink`, `sit_restaurant`, `city_rest`, `city_park_fun`, `city_karaoke`.

### 7–10. Stage 3 and full city

`AgencyGate` `(-7.2, 0, 0)`, `AgencyGateLeisure` `(-21.8, 0, 13.6)`, `district_id=agency_row`.  
Unlock: `SALARY_MINE` at `STAGE_3`.

Stage 3 `action_id`s: `open_photo_studio`, `open_barber`, `claim_day_job`, `city_bus_info` / `city_buy_gift`.

### 11. Save / load districts

No separate city-district save blob. Gates follow Story/GameState:

- `is_feature_unlocked` is `stage >= get_feature_unlock_stage(feature)`
- `district_gate_sync` refreshes on `_ready`, `feature_unlocked`, and `stage_changed`

Loading a save that restores stage therefore restores gate state without a new save format.

### 12. No city visual assets in prototype city

Grep of `art/city.tscn` and `prototype/`: **no** `gltf` / `glb` / `fbx` / `downtown`.  
`city.tscn` ext_resources are only prototype PackedScenes, `DistrictGate.tscn`, and `district_gate_sync.gd`.

Old GLTF POI scenes remain under `art/poi/` and `art/prefabs/` unused by this city.

### PackedScene integrity

`city.tscn` has **no** shop `InteractionArea` nodes. Sample live instances:

- PlayerHome InteractionArea `go_home` inside the home scene
- Cafe `sit_cafe`
- Cinema `sit_cinema`
- Agency `claim_day_job`
- DuckFeeding `city_park_fun`

Moving a POI root moves visual, collision, areas, markers, and signage together.

## Runtime evidence

GodotIQ `verify_project_runs(scene=city_hub.tscn)`:

- script check: 0 errors
- play: `runtime_attached: true` (~2.6 s)
- debug console: 0 runtime / 0 script errors

Follow-up `state_inspect` / game `exec` / game `screenshot` **timed out** (5–30 s) while `read_debug_console` still reported `game_running: true` and 0 errors. The runtime MCP bridge did not return player position or in-game frames. Layout proof is the opened editor PNGs above, not a filename-only claim.

Full on-foot walk of every POI, gate close/open, and save/load round-trip should be confirmed in a normal play session (apartment → city), which this bridge pass did not complete.

## Structure checks that did complete

- Donor origins/yaw restored on all listed POI
- Stage roots use real `district_id` + `progression_stage` metadata
- DistrictGates are instances of `DistrictGate.tscn` at donor positions
- Roads/Boundaries are PackedScene instances with RoadSurfaces / Sidewalks / Curbs / Crossings
- Hub old 12 m floor/walls: `visible = false`, floor collision `disabled` / layer 0
- No decorative benches/cars/trees/lights added in the prototype city

## Stop

No further decoration or layout polish. Waiting on visual review.
