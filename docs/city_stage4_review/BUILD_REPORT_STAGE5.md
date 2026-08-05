# BUILD_REPORT — City Stage 5 Visual Repair

Status: `IMPLEMENTED — MANUAL CHECK REQUIRED`

## Scope kept from Stage 4

- marker-driven interactions
- district unlock / persistence / CityAPI
- three `district_gate` nodes (`ParkGate`, `AgencyGate`, `AgencyGateLeisure`)
- action IDs and save keys
- Stage 4 validator infrastructure (`VALIDATE_CITY_STAGE4_PASS`)

## What changed

Visual/playability repair pass over authored city environment:

1. Continuous L-shaped commercial/residential streets with curbs + sidewalks (CSG slabs under `GeneratedCity/Streets`)
2. Compact central pocket with edge fountain + sightline paving
3. Cafe Two Hearts: side seating, compact `TWO HEARTS` sign, no sushi billboard
4. District gates: low rest opacity (~0.12), thin frame rails, label only on focus
5. Park: grass/soil/path loop, pond rim + collision, perimeter trees, restaurant warm sign (`PARK BISTRO`)
6. Leisure forecourt pad + queue rail + neon practical lights; arcade cabinets under awning nook
7. Agency lane fillers, bus end wall, amber/cyan accents
8. Closer background massing / alley closures to hide void edges
9. Spawn moved ~8–9 m from cafe door; markers/manifest synced
10. New FPS review package + route notes

## Changed / created files

- `scenes/art/city/backups/city_before_stage5_visual_repair.tscn`
- `scenes/world/city/city.tscn` (Stage 5 visual rebuild)
- `scenes/art/city/prefabs/district_gate.gd`
- `scenes/art/city/prefabs/DistrictGate.tscn` / `CafeTwoHearts.tscn` / `ParkRestaurant.tscn` / `ArcadeFacade.tscn` / `CinemaFacade.tscn` (via builders)
- `scenes/world/complex_world.gd` (gate styling defers to DistrictGate script)
- `tools/build_city_stage5_visual_repair.gd`
- `tools/capture_city_stage5_review.gd`
- `tools/date_factory_city_stage5_visual_layout.json`
- `tools/date_factory_city_stage4_build_manifest.json` (positions/nav synced for validator)
- `tools/build_city_stage4.gd`, `tools/build_city_poi_prefabs.gd` (prefab visual fixes)
- `docs/city_stage4_review/BUILD_REPORT_STAGE5.md`
- `docs/city_stage4_review/VALIDATION_REPORT_STAGE5.md`
- `docs/city_stage4_review/13_full_loop_route_notes.md`
- Stage 5 PNGs listed below

## Headless / technical checks

| Check | Result |
|---|---|
| `build_city_stage5_visual_repair.gd` | `STAGE5_VISUAL_REPAIR_OK` |
| `validate_city_stage4.gd` | `VALIDATE_CITY_STAGE4_PASS` |
| Stage 5 GPU capture package | `CAPTURE_CITY_STAGE5_PASS` (12 shots) |

## Screenshot package

- `01_topdown_locked.png`
- `02_topdown_all_open.png`
- `03_spawn_view.png`
- `04_spawn_to_cafe_wide.png`
- `05_commercial_street_both_directions.png`
- `06_central_pocket_to_both_gates.png`
- `07_park_gate_locked_restaurant_visible.png`
- `08_park_loop_pond.png`
- `09_leisure_forecourt_wide.png`
- `10_agency_gate_central_side.png`
- `11_agency_gate_leisure_side.png`
- `12_agency_lane_wide.png`

## Manifest deviations

1. POI/marker/gate transforms intentionally adjusted for denser streets and park reveal; Stage 4 manifest JSON synced so technical validation still passes.
2. Continuous streets use authored CSG slabs (not only megakit road tiles) for curb/sidewalk continuity.
3. GodotIQ MCP unavailable; rebuild via headless SceneTree tools.
4. Full in-game unlock/save loop not automated here — see route notes.

## Known remaining visual risks

- Some megakit facades still share brick rhythm; variety is via accents/awnings/lights, not full unique kits.
- Standalone `city.tscn` WorldEnvironment is nulled when mounted in `complex_world`; final night grade depends on game lighting.
- Gate transparency is improved but still a plane barrier — destination readability should be confirmed in play.
- Edge closures reduce void, but extreme map corners can still show dark sky without a skybox.

## Hard criteria status (pre-manual)

| Criterion | Technical/capture evidence | Needs player |
|---|---|---|
| Cafe entrance unobstructed | Prefab seating moved aside | Confirm walk-in |
| Continuous commercial street | CSG road/sidewalk/curbs | Eye-level walk |
| No giant planters in route | Wall-hugging planters only | Confirm |
| ParkGate not full-screen opaque | alpha ~0.12 + thin frame | Confirm restaurant % |
| Restaurant framed beyond gate | warm sign + lamps + capture 07 | Confirm |
| Park path/pond/landscape | grass/path/rim built | Confirm |
| Leisure forecourt | pad + framing POIs | Confirm |
| Agency dense street | fillers + bus end wall | Confirm |
| AgencyGateLeisure valid | corridor pad + capture 11 | Confirm traverse |
| No major void on route | edge massing | Confirm |
| Full unlocked loop | route notes prepared | **Required** |
| Stage4 validation | PASS | — |
