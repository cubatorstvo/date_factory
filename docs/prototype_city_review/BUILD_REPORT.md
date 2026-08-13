# Prototype City — Build Report

## 0. Snapshot before this work

- Branch: `main`
- Commit: `3d1bee3` — `До разработки прототипа города`
- Pushed to `origin/main`
- `.godot/` cache was not committed

City changes started only after that commit + push.

## 1. Donor vs working scenes

| | Path |
|---|---|
| Donor city (read-only) | `../date_factory_legacy/scenes/world/city/city.tscn` |
| Working playable location | `res://world/locations/city_hub/city_hub.tscn` |
| Working visual city | `res://world/locations/city_hub/art/city.tscn` (hub child `Geometry/DonorCity`) |

Donor is not edited. Asset files (GLTF/POI prefabs) stay in the repo and are simply unused by the prototype city.

### Donor districts (kept)

Existing ids, not invented names:

| Stage | `district_id` | City root |
|---|---|---|
| 1 | `main_street` | `Stage1_MainStreet` |
| 2 | `park_leisure` | `Stage2_ParkLeisure` |
| 3 | `agency_row` | `Stage3_AgencyRow` |

### Donor POI (layout restored)

Home, Cafe, flower/gift pair, jewelry/clothing pair, Homeware, InternetCafe, Bookstore, Gym, Cinema, Arcade, Bar, ParkRestaurant, PhotoStudio, Barber, Agency, MainBench, ParkBench, DuckFeeding, Karaoke, BusStopCandy.

Gates:

- ParkGate `(0, 0, 7.2)` → `park_leisure`
- AgencyGate `(-7.2, 0, 0)` yaw 90 → `agency_row`
- AgencyGateLeisure `(-21.8, 0, 13.6)` → `agency_row`

Spawn: `(29.2, 0, 9)`

### Systems that depend on the city

- `WorldLocation` / `city_hub` spawn + `WorldTransition` travel
- Story features / `GameState` stage (`PUBLIC_CITY_ACCESS`, `SALARY_MINE`)
- `DistrictGate.set_unlocked()` (now driven by `district_gate_sync.gd`)
- `PublicCityGate` (`WorldFeatureGate`) on the hub — kept for tests; bollard GLTF removed
- Agency `claim_day_job` (`OfficeDayJobInteractable`)
- Art POI `InteractionArea` stubs (`donor_interactable_stub.gd`) keep `action_id` / display fields
- NPC / story-point / flavor interactables on the hub (nodes kept, city visual assets not used)

There is no donor `Game.city` / `CityDistricts` API in the rewrite.

## 2. What changed

- Stripped GLTF/building/prop/road instances from `art/city.tscn`
- Rebuilt layout as primitive PackedScenes at **donor coordinates** (not the later compressed hub coordinates)
- Organized instances under Stage1/2/3 using real `district_id`
- New prototype road + sidewalk + curb + crossing kit
- Prototype boundaries + floor collider
- `district_gate_sync.gd` on city root
- Hub spawn / transitions / lights moved onto donor markers
- Old 12 m hub box walls hidden; collision disabled
- Hub bollard meshes removed; `PublicCityGate` collision kept at ParkGate position

Builder (editor-only, not runtime): `res://tools/build_prototype_city.gd`

## 3. Deviations (no extra level-design)

1. **Compressed hub layout was discarded.** Pre-prototype `art/city.tscn` had shrunk POI positions while donor roads stayed at full scale. Prototype restores donor origins/yaw.
2. **Pair shops stay one PackedScene with two tenants** (`RetailPairFlowerGift`, `FashionPairJewelryClothing`) so the donor footprint is one building. Split later if wanted.
3. **Prototype path** is `world/locations/city_hub/prototype/`, not `scenes/art/city/prototype/`.
4. **Gate unlock** uses Story features, not missing `Game.city`:
   - `park_leisure` → `StoryFeature.PUBLIC_CITY_ACCESS` at `GameStage.STAGE_2`
   - `agency_row` → `StoryFeature.SALARY_MINE` at `GameStage.STAGE_3`
   - `main_street` has no DistrictGate
5. **Double barrier at park:** hub `PublicCityGate` (feature collision) + city `ParkGate` (visual DistrictGate) share `(0, 0, 7.2)`.
6. **Hub flavor nodes** (bench text, etc.) remain as gameplay/story, not city decoration. Their GLTF props were stripped/hidden where they were city visual assets.
7. **Background house scale** is primitive massing at donor transforms, not the old 0.45–0.5 GLTF scale. Footprints may read larger than the packed GLTFs. Coordinates were not moved.

## 4. What was not changed

- `poi_id` / `action_id`
- Save schema
- Stage progression rules
- DistrictGate look (same reusable scene)
- Asset files on disk (only unused by prototype city)
- No new decorative props

## 5. Color coding

- Stage 1: warm neutrals
- Stage 2: greener park + leisure accents
- Stage 3: cooler / stricter agency masses
- POI: more saturated individual colors
- Background houses: less saturated
