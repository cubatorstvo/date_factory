# RC-AUDIT-WORLD-001 — World / POI Baseline Audit

**Project:** DATE FACTORY  
**Date:** 2026-08-05  
**Agent:** df-researcher (read-only)  
**Writable scope:** this file only  
**Method:** GodotIQ `project_summary` → `file_context` / `scene_map` / `dependency_graph` / `asset_registry` (brief/filter) + targeted code/docs cross-check. **No windowed Godot run.**  
**Working tree note:** Uncommitted QA full-access save + proxy POC changes present — observed, not modified.

**Audit verdict:** PASS (baseline inventory complete)  
**World release readiness:** NOT READY (see defects + PENDING VISUAL REVIEW)

---

## Existing flow

### Boot → home FPS
1. `boot.tscn` → New Game / Continue → `main.tscn`.
2. `ComplexWorld` (`complex.tscn` + `complex_world.gd`) starts `_current_location=home`, `_home_zone=apartment`.
3. Mounts `apartment.tscn` as `ApartmentVisual`; binds furniture interacts + outlines; neighbor room co-loaded when unlocked; lab / `apt_*` **not** co-spawned.
4. Player FPS at `Markers/PlayerSpawn` (or fallback).

### Home ↔ city (mutually exclusive)
| Action | Route | Spawn |
|--------|-------|-------|
| Exit door «На улицу» | `go_outside` → `travel_to(city, HomeEntrance)` | City `Markers/HomeEntrance` |
| City «Мой дом» | `go_home` → `travel_to(home, PlayerSpawn)` | Apartment spawn |
| Basement / elevator | `go_lab` / `elevator_travel` / `open_elevator` | Exclusive home zones |
| Neighbor knock | `go_neighbor` teleport (same home tree) | Neighbor greybox |

`travel_to` blackout via `TransitionOverlay`; unlocks `_date_lock` after fade. City root scaled `CITY_WORLD_SCALE=1.5`.

### City districts (progression)
| District | Default | Unlock | Physical gate |
|----------|---------|--------|---------------|
| `main_street` | open | start | — |
| `park_leisure` | locked | stage_2 **or** venue `park` | `Decor/ParkGate` |
| `agency_row` | locked | stage_3 **or** room `agency` | `Decor/AgencyGate` (west of park) |

Gates: semi-transparent barrier + `inspect_district_gate` → `DistrictGateUI`. Agency only reachable after park wall opens (topology, not a bug).

### Dating / venues (no walkable interiors)
Phone books place → player walks to street POI → `sit_*` / overlay UI. Date presentation uses `date_stage.gd` backdrops (`restaurant.tscn` / procedural park-cinema-arcade), **not** `travel_to` into shop/restaurant interiors.

### Persist
`CityAPI.to_dict` / `from_dict`: districts, amenities cooldown, gym/photo day, style, apartments, `outside_tip_shown`. Location itself is not a long-lived world coordinate — reload rebuilds active zone from save + facility unlocks.

---

## Full scene inventory

GodotIQ project: **47 scenes**, **96 scripts**, autoloads `GodotIQRuntime`, `EventBus`, `SettingsService`, `Game`.

### Main-game / travel locations

| Scene | Role | Main-game entry | Interior? | Assets vs blockout | Notes |
|-------|------|-----------------|-----------|-------------------|-------|
| `scenes/boot/boot.tscn` | Menu | OS launch | UI | UI | Continue may use QA full-access profile (uncommitted) |
| `scenes/boot/main.tscn` | Game shell | From boot | hosts world+UI | — | Owns `DateStage`, overlays |
| `scenes/world/complex.tscn` | World root | Instanced in main | — | Sun + WorldEnvironment | Sole live outdoor lighting authority after mount strip |
| `scenes/world/vertical_slice/apartment.tscn` | Player apt art | Boot home | Yes | Art slice | Outline-bound furniture |
| `scenes/world/city/city.tscn` | City art (183 nodes) | `travel_to(city)` | Street only | Kit buildings + CSG props/districts | Mounted as `CityVisual` @ (−30,0,0) |
| `scenes/art/lab/Clone_Lab_Base.tscn` | Lab art | Basement/elevator | Yes | Art kit | Tech sun/env stripped on mount |
| Themed apt (procedural) | `apt_cozy/modern/creative` | Elevator / board | Greybox rooms | Primitives | No dedicated `.tscn` |
| Neighbor / office / agency / mansion / factory / orbital | Facility expansion | Stage unlocks in home tree | Greybox | Primitives | Not separate travel IDs except lab/`apt_*` |

### Date / presentation (not city travel)

| Scene | Role | Entry |
|-------|------|-------|
| `scenes/world/vertical_slice/restaurant.tscn` | Date backdrop | `date_stage` when place=restaurant/cafe-like |
| Procedural park/cinema/arcade in `date_stage.gd` | Date backdrop | sit_* after booking |

### Parallel / unused / testbed (not normal FPS route)

| Scene | Status |
|-------|--------|
| `scenes/world/vertical_slice/street.tscn` (115 nodes) | Legacy mirror; **not** `CITY_SCENE` |
| `scenes/art/city/City_Street_Slice.tscn` | Art testbed / kit slice |
| `scenes/art/city/City_Street_KitInstances.tscn` | Kit index |
| `scenes/art/kits/*_Kit_Index.tscn` | Catalog |
| `scenes/art/restaurant/Sushi_Date_Restaurant.tscn` | Art kit; not ComplexWorld mount |
| `scenes/art/rooms/Apartment_Blockout_Finalized.tscn` | Art/blockout |
| `scenes/art/factory/*` | Facility art kits |
| `scenes/art/testbeds/*` incl. ProxyGirl POC | Debug only (uncommitted POC) |
| UI scenes under `scenes/ui/*` | Overlays |
| `scenes/player/player.tscn`, `scenes/characters/girl.tscn` | Actors |

`asset_registry` (path `scenes/world`): 5 scenes, **2 used / 3 unused** — aligns with `street.tscn` + vertical_slice extras not referenced by live mount constants.

---

## POI matrix

Legend: **Avail** = reachable in main game when unlocks met. **Interior** = separate loadable room. **Visual** = art facade vs hidden/grey. Colliders: Interactable owns `BoxShape3D` unless `attach_to_host` (apartment furniture only). City art-backed POIs use **FocusProxy** outline (not bound to building meshes).

### A. Main street (always after `go_outside`)

| POI | Purpose | Facade/sign | Interior | Assets | Lighting | Coll/nav | Interact | Outline | Spawn after exit | Control return | Repeat | Save | Runtime risks |
|-----|---------|-------------|----------|--------|----------|----------|----------|---------|------------------|----------------|--------|------|---------------|
| Home door | Return home | `PlayerHomeFacade` + `HomeDoorGlow` | Apt | Kit | Omni glow | Interact + art static | `go_home` | FocusProxy | `PlayerSpawn` | Yes (travel unlock) | Yes | N/A | Spawn Z marker vs old fallback mismatch if marker missing |
| Cafe Two Hearts | sit-wait date | `CafeSign` / `NorthBlockCafe` / `CafeHalo` | No (date stage) | Kit+CSG sign | CafeHalo Omni | Interact hardcoded (−19.5,−4.35) ≈ marker+offset | `sit_cafe` | FocusProxy | Stay city | Yes | Needs booking | Booking in dating save | Silent if no booking |
| Flower shop UI | Shop overlay | Near shop row (hardcoded −24,2) | No | Interact only / generic blocks | Ambient | Interact | `open_flower_shop` | FocusProxy | Stay | UI close | Yes | Inventory/economy | Weak facade binding |
| Jewelry | Shop UI | hardcoded −26.5,1.5 | No | same | Ambient | Interact | `open_jewelry_shop` | FocusProxy | Stay | UI | Yes | Economy | same |
| Gift shop | Shop UI | −22,3 | No | same | Ambient | Interact | `open_gift_shop` | FocusProxy | Stay | UI | Yes | Economy | same |
| Clothing | Shop UI | −23.2,3.6 | No | same | Ambient | Interact | `open_clothing_shop` | FocusProxy | Stay | UI | Yes | Economy | same |
| Homeware | Shop UI | −21.2,3.6 | No | same | Ambient | Interact | `open_homeware_shop` | FocusProxy | Stay | UI | Yes | Dating homeware | Cost can be extreme (QA saw $100000) |
| ParkGate | District barrier | CSG barrier | — | CSG | Unshaded alpha | StaticBody collision | `inspect_district_gate` | Probe FocusProxy | — | UI | Until unlock | Districts in CityAPI | Probe placement +X of gate |
| Talk girls / wanderers | Contact | Capsule/Girl mesh | — | Character | — | Area talk | `talk_girl` | Character | — | Toast | Cooldown snub | City roster | Placeholder capsules if art fails |

### B. Park / leisure (behind ParkGate)

| POI | Purpose | Facade | Interior | Assets | Interact | Gate check | Notes |
|-----|---------|--------|----------|--------|----------|------------|-------|
| Picnic | sit park date | Park CSG + benches | Date backdrop park | CSG | `sit_park` | Bookability | Marker `ParkPicnicSpot` |
| Park restaurant | sit restaurant | **`ParkRestaurant` CSG size (0,0,0)** + kit `RestaurantFacade` elsewhere | Date uses `restaurant.tscn` | Broken CSG + kit | `sit_restaurant` | Bookability | Landmark gap |
| Gym | Workout UI | `GymFacade` CSG | No | CSG | `city_workout` | `is_leisure_unlocked` | Marker `GymEntrance` |
| Gym pass | Max attention | near gym | No | — | `city_gym_pass` | Soft (spend) | No leisure toast gate on pass |
| Bookstore | Shop UI | `BookstoreFacade` CSG | No | CSG | `open_bookstore` | leisure | |
| Cinema | sit cinema | `CinemaFacade` CSG | Date procedural | CSG | `sit_cinema` | booking | |
| Arcade play | Minigame | `ArcadeFacade` CSG | Procedural | CSG | `open_arcade` | `is_arcade_bookable` | |
| Arcade date | sit arcade | same strip | Procedural | — | `sit_arcade` | booking | Offset +1.2 from entrance |

### C. Agency row (behind AgencyGate)

| POI | Purpose | Facade | Interior | Interact | Gate |
|-----|---------|--------|----------|----------|------|
| Photo studio | Shoot/publish UI | `PhotoFacade` CSG + soft light | No | `open_photo_studio` | agency unlock |
| Barber | Style tags UI | `BarberFacade` + neon | No | `open_barber` | agency; **mesh not updated** |
| Agency office | Schedule board | `AgencyFacade` | No | `open_agency_board` | agency |

### D. Home-cluster POIs (not city street)

| Zone | Key POIs | Visual | Notes |
|------|----------|--------|-------|
| Apartment | job, wardrobe, fridge, drawers, table, phone, expand, exit, neighbor, elevator, basement | Art + bound outlines | Collider ownership on furniture hosts |
| Neighbor | look, return, talk NPC | Greybox | Teleport, not travel_to |
| Lab | create_clone ×2, elevator | Clone_Lab_Base | Scientist/unlock_clones gated |
| apt_* | prep table, wardrobe, elevator | Greybox colors | Buy via elevator/board |
| office_nook / agency / mansion / factory / orbital | hire/upgrade/finale stations | Greybox | Stage expansion; co-loaded with apartment when unlocked |

---

## Street activities

| Activity | action_id | Source | Visible prop in live city? | Unlock | Effect | Persistence |
|----------|-----------|--------|----------------------------|--------|--------|-------------|
| Street bench rest | `city_rest` | `city_builder` plaza | Art has `BenchNorth/South` CSG but **interact not bound**; builder meshes **hidden** | Main street | +attention × amenity mult | `amenity_last_use` |
| Park bench | `city_rest` bonus 1.5 | `city_builder` park | Park benches CSG exist; interact unbound | Physically behind ParkGate | Stronger attention | Amenity |
| Corner flower (−20%) | `city_buy_gift` flower | `city_builder` corner shop | **Hidden greybox** — parallel to UI flower shop | Main (south) | Inventory gift | Economy |
| Corner candy | `city_buy_gift` | same | Hidden | Main | Gift | Economy |
| Internet cafe PCs | `city_cafe_job` / `city_cafe_scroll` | builder | Hidden | Main (north) | Money / popularity | — |
| Coffee | `city_coffee` | builder | Hidden | Main | $8 → attention | — |
| Feed ducks | `city_park_fun` | builder park «Кормушка» | **No duck art**; hidden prop | Checks `park_leisure` | +popularity × amenity | Amenity |
| Night bar drink | `city_bar_drink` | builder ~−44 | Hidden; between park & agency gates | No soft unlock (physics gate) | $15 scandal+pop | — |
| Karaoke | `city_karaoke` | builder night bar | **No karaoke booth art** | No soft unlock | +pop +scandal toast | — |
| Bus schedule | `city_bus_info` | builder −50 | Hidden; **west of AgencyGate** | No soft unlock | Toast only | — |
| Bus candy machine | `city_buy_gift` | builder | Hidden | Behind agency wall | Gift | — |

**Flower shop duality:** art-backed `open_flower_shop` (UI catalog) **and** invisible corner `city_buy_gift` discount — easy player confusion.

**Bench route:** Plaza interact at builder (−12,+2.5) vs Decor benches — player may see benches without reliable prompt, or get prompt in empty plaza air. **PENDING VISUAL REVIEW.**

---

## Current city topology (text map)

Coordinates: `CityDistrict` / pre-scale local. Art mounted at **x−30**. Player scale ×1.5 on whole city_root. Axis: **+X east (home)**, **−X west (park → agency → bus)**, ±Z sidewalks.

```
EAST ════════════════════════════════════════════════════════════ WEST
[~+18 art / ~−11.5 root]     HOME facade + HomeEntrance + go_home
         │
   Main street corridor (kit N/S blocks, road, lamps, CSG benches)
   Cafe @ ~art x10.5 / root −19.5  (Two Hearts sign + sit_cafe)
   Shop interacts clustered ~ root −21…−26 (UI shops; weak facades)
   Plaza amenities ~ root −12 (bench/rest — builder, visuals hidden)
   Corner shop ~ (−18,−6) | Internet cafe ~ (−22,+6)  [hidden grey]
         │
   ParkGate @ art x−2.5 / root ~−32.5  ── barrier until park_leisure
         │
   ParkLeisure + LeisureStrip (CSG facades: gym/book/cine/arcade)
   Picnic / park rest / ducks @ park ~ (−36…−38,+4)
   Restaurant interact @ ParkRestaurantEntrance (CSG park shell size 0)
         │
   AgencyGate @ art x−15.5 / root ~−45.5 ── until agency_row
         │
   AgencyRow CSG: photo / barber / agency
   Night bar / karaoke builder @ −44 (between gates; hidden)
   Bus stop builder @ −50 (behind agency; hidden)
WEST / WestEndBlock + WestVoidFill / NorthVoidBlock (edge blockers)
```

**Composition diagnosis**
- **Long E–W corridor:** intentional hub spine; sightlines along road; home east, gated west progression.
- **Zones:** main_street → park_leisure → agency_row (linear, not loops).
- **Loops:** none; no back alleys as routes.
- **Edges:** CSG void fills / end blocks; world invisible ground under complex.
- **No NavigationRegion3D** in city path — NPC wander uses waypoint arrays only.

---

## Lighting diagnosis

| Layer | Behavior | Effect |
|-------|----------|--------|
| `complex.tscn` `WorldEnvironment` | `background_energy_multiplier=0.24`; **ambient** Color(0.29,0.19,0.28) energy 0.58; tonemap ACES-like exposure 1.08 | Magenta/plum ambient wash — known street darkness + pink bias |
| `complex` `Sun` DirectionalLight | Stage &lt;5: warm Color(1,0.82,0.68) **energy 0.28**; stage≥5 cooler blue energy 0.42 | Dim key light → grey corridor read |
| Mounted `city.tscn` `WorldEnvironment` | **Cleared** (`environment=null`) on mount | City sky/ambient discarded |
| Mounted `NightKey` + other DirectionalLights | **`visible=false`** on mount | City authored key lost |
| City Omni (lamps, CafeHalo, HomeHalo, park/agency) | Kept; `_tone_down_slice_lights` clamps energy / remaps magenta | Local pools only; mid-street still dark |
| Time of day | Game `TimeAPI` advances clock; **does not drive** outdoor sun/sky | HUD time ≠ visual day cycle |

**Root cause of “dark corridor / bad lighting”:** dual WorldEnvironment fight resolved by stripping city env + disabling city sun, leaving a **single dim sun + purple ambient** over a long narrow street. Not a missing lamp mesh alone.

Apartment/lab have their own env stripped similarly; complex WE remains global.

---

## Reusable systems

| System | Path | Reuse for hardening |
|--------|------|---------------------|
| Exclusive travel | `ComplexWorld.travel_to` | Do not dual-load city+home |
| City build + hide grey | `CityBuilder` + `_hide_generated_visuals` | Replace hidden amenities with art-bound interacts |
| District gates | `CityDistricts` + gate sync | Keep GTA-style barriers |
| Interaction | `Interactable` + `InteractionRouter` | Single action_id catalog |
| Outline | `interact_outline.gdshader` + `bind_outline_root` | Prefer bind city props like apartment |
| Amenities cooldown | `CityAPI.amenity_*` | Already persisted |
| Date places | `DatePlaces` / `DateSchedule` | Bookable venues |
| Date presentation | `date_stage.gd` | Keep overlays vs interiors |
| Shop UI | `_open_shop_menu` | Overlay pattern for all shops |
| Elevator / board | `elevator_ui`, `agency_board_ui` | Home-zone travel |
| Markers | `city.tscn/Markers/*` | Prefer markers over hardcodes |

---

## Integration boundaries (safe for future masterplan)

**Safe to change without rewriting Game façade**
- `scenes/world/city/city.tscn` art/props/lights (keep marker names).
- Binding city interacts to Decor meshes (mirror apartment `_bind_interact_outline`).
- Replacing CSG leisure facades with kit instances.
- Complex `Environment` / Sun values (lighting pass).
- Hiding or deleting unused `street.tscn` after confirming no tools.

**Hot / single-writer**
- `complex_world.gd`, `city_builder.gd`, `interaction_router.gd`, `city_api.gd`, `date_places.gd`, `complex.tscn`, `project.godot`, save schema.

**Do not**
- Propose new POI (out of scope).
- Co-spawn city+home physics.
- Mount second WorldEnvironment without strip policy change.
- Treat testbeds / proxy POC as release route.
- Parallel second city framework.

---

## Scene / POI gaps (no new POI — gaps in existing)

1. No walkable interiors for cafe/shops/gym/cinema/arcade/photo/barber — overlay-only (accepted pattern; document as intentional).
2. `ParkRestaurant` CSG **zero size** — park restaurant landmark missing.
3. Street amenities (bench interact, ducks, karaoke, corner flower, internet cafe, bus) **gameplay without readable art**.
4. City venue outlines not mesh-bound (FocusProxy only).
5. Dual flower purchase paths.
6. `street.tscn` / art street slices unused by live mount.
7. Leisure/agency facades still CSG labels, not kit storefronts.
8. Themed apts / facility rooms greybox.
9. Barber does not alter Hero mesh.
10. No navmesh; no day-night visual sync.
11. Hardcoded shop/cafe positions vs markers (cafe OK by coincidence; shops lack markers).

---

## Defects (severity / repro / evidence / owner / regression)

### D1 — Global outdoor lighting too dark / plum wash
- **Severity:** High (player-facing readability)
- **Repro:** New Game → exit to city; observe mid-street vs cafe halo.
- **Evidence:** `complex.tscn` Environment ambient purple + sun energy 0.28; city WE/sun stripped in `_mount_visual_scene`. Docs: `FOCUSED_POLISH_REPORT`, correction lighting notes. **Visual: PENDING VISUAL REVIEW**
- **Owner:** lighting / `complex.tscn` + `complex_world.gd` mount policy
- **Regression:** FPS screenshot mid-street + cafe entrance luminance checklist; assert single WE + min sun energy

### D2 — Street amenity visuals hidden (bench/ducks/karaoke/corner/bus/netcafe)
- **Severity:** High (invisible gameplay)
- **Repro:** After park unlock, walk to park feeder / night bar / plaza; look for props vs prompt-only.
- **Evidence:** `_hide_generated_visuals` after `CityBuilder.build`; no duck/karaoke art nodes in `city.tscn`. **PENDING VISUAL REVIEW**
- **Owner:** city art + `complex_world` interact bind
- **Regression:** each amenity has visible mesh within 1.5m of Interactable; screenshot pack

### D3 — ParkRestaurant CSG size (0,0,0)
- **Severity:** Medium
- **Repro:** Inspect `Districts/ParkLeisure/ParkRestaurant` in editor/scene_map; approach restaurant POI.
- **Evidence:** `city.tscn` size Vector3(0,0,0). **PENDING VISUAL REVIEW**
- **Owner:** city scene
- **Regression:** non-zero AABB + screenshot of park restaurant facade

### D4 — Flower shop dual paths
- **Severity:** Medium (UX / economy)
- **Repro:** Use `open_flower_shop` vs find corner «Цветы со скидкой».
- **Evidence:** `complex_world` + `city_builder` + router cases.
- **Owner:** city design / interaction
- **Regression:** single canonical flower purchase in acceptance matrix

### D5 — Karaoke / bar / bus lack district soft-gates (physics only)
- **Severity:** Low–Medium
- **Repro:** If gate collision fails, actions still run without unlock toast (unlike `city_park_fun`).
- **Evidence:** router: only ducks check district; karaoke/bar/bus do not.
- **Owner:** `interaction_router.gd`
- **Regression:** locked district → toast; unlocked → effect

### D6 — City POI outline/collider not owned by facades
- **Severity:** Medium
- **Repro:** Focus shop/cafe interact — proxy box vs building silhouette.
- **Evidence:** `_add_interact` art_backed → FocusProxy; `_bind_interact_outline` only apartment.
- **Owner:** `complex_world.gd`
- **Regression:** bind paths for CafeSign / shop hosts like apt furniture

### D7 — No NavigationRegion; waypoint-only NPCs
- **Severity:** Low (current) / Medium if denser AI planned
- **Evidence:** no NavRegion under city; `_city_data.waypoints`
- **Owner:** city systems
- **Regression:** N/A until nav introduced

### D8 — Time API ≠ outdoor lighting
- **Severity:** Low (immersion)
- **Evidence:** `_update_stage_lighting` by stage_id only
- **Owner:** time + lighting
- **Regression:** optional hour→sun curve smoke

### D9 — Legacy `street.tscn` unused
- **Severity:** Low (maintenance trap)
- **Evidence:** `CITY_SCENE` points to `city/city.tscn`; asset_registry unused count
- **Owner:** cleanup
- **Regression:** grep mount path == city.tscn

### D10 — Long corridor composition / void edges
- **Severity:** Medium (feel)
- **Evidence:** topology; prior polish reports “dark greybox corridor”; void blocks present. **PENDING VISUAL REVIEW**
- **Owner:** city composition masterplan
- **Regression:** sightline screenshots home→cafe→ParkGate

---

## Risks

1. Hardening lighting without re-enabling city WE may still look wrong if ambient stays plum.
2. Un-hiding CityBuilder boxes without deleting them → double mesh with CityVisual.
3. Parallel writers on `complex_world.gd` during QA/proxy work.
4. Overlay-only venues may be mistaken for “missing interiors” in release notes — clarify intentional.
5. QA full-access save can mask unlock/gate bugs during manual smoke.
6. Proxy POC testbeds must not enter release path.
7. Homeware extreme prices break economy smoke if treated as normal.

---

## Recommended ownership

| Package | Writer | Writable | Forbidden |
|---------|--------|----------|-----------|
| RC-LIGHT-CITY-001 | df-scene-worker or lighting owner | `complex.tscn` Environment/Sun; optional city Omni only | `city_builder` logic, save |
| RC-CITY-AMENITY-ART-001 | df-asset-worker + df-scene-worker | `city.tscn` props for bench/ducks/karaoke/bus; marker adds | New POI types |
| RC-CITY-INTERACT-BIND-001 | df-gameplay-worker | `complex_world.gd` bind outlines + marker-driven shop positions | apartment binds rewrite scope creep |
| RC-CITY-GATE-SOFTLOCK-001 | df-gameplay-worker | `interaction_router.gd` district checks for bar/karaoke/bus | District redesign |
| RC-CITY-RESTAURANT-FACADE-001 | df-scene-worker | `ParkRestaurant` CSG / kit facade | date_stage restaurant |
| RC-CLEANUP-STREET-LEGACY-001 | df-researcher/orchestrator decision then worker | deprecate `street.tscn` refs | delete without grep |

Keep **one writer** on `complex_world.gd` / `city.tscn` at a time.

---

## Evidence gaps

| Need | Status |
|------|--------|
| FPS screenshots: home exit, cafe, mid-street, ParkGate closed/open, leisure strip, agency, bench, ducks, karaoke | **PENDING VISUAL REVIEW** (no windowed run this audit) |
| Raw Godot log of city travel | Not captured this session; prior QA: `docs/agent/qa/QA-FULL-ACCESS-SAVE-001_QA.md` (functional POI smoke, not visual polish) |
| Historic frames | `docs/asset_validation/screenshots/02_city_street.png`; vertical_slice polish/correction reports (may be stale) |
| Navmesh / collision penetration tests | Not run |
| Save/load mid-city | Not retested here (CityAPI fields exist) |

**Do not mark visual PASS** until rendered walk reviewed.

---

## Acceptance evidence (for future hardening)

Minimum bundle per city hardening milestone:
1. Git diff scoped files.
2. Headless parse/check_errors on touched `.gd`.
3. One windowed capture route: apt → city HomeEntrance → cafe sign → ParkGate → picnic → leisure → AgencyGate → photo; quit.
4. Raw Godot log path + screenshots opened by Orchestrator.
5. Amenity visibility checklist (bench, ducks, karaoke, flower canonical).
6. Lighting stills vs VISUAL_BIBLE (no magenta wash, readable facades).
7. Independent `df-qa-worker` report.
8. Save/load still Continuable after city visit.

---

## Commands / tools used (this audit)

- GodotIQ: `godotiq_project_summary(detail=brief)`
- GodotIQ: `godotiq_file_context` on `complex_world.gd`, `city_builder.gd`, `complex.tscn`, `city.tscn`, `main.tscn`, `interaction_router.gd`, `city_api.gd`, `street.tscn`, `restaurant.tscn`, `main.gd`
- GodotIQ: `godotiq_scene_map` on `City_Street_Slice`, `complex.tscn`, `city.tscn` (Markers/Decor/HomeEntrance)
- GodotIQ: `godotiq_dependency_graph(complex_world.gd)`, `godotiq_asset_registry(scenes/world)`
- Shell: list `scenes/**/*.tscn`; confirm `city.tscn` exists
- Read/grep: `DATING_AND_WORLD.md`, `CITY_HUB_EXPANSION_REPORT.md`, `KNOWN_LIMITATIONS.md`, router/city_builder/complex_world sections

**Not run:** Godot windowed play, explore screenshots, headless game session.

---

## Audit summary for Orchestrator

Baseline world/POI map is complete: exclusive home↔city travel, three gated districts on a long E–W corridor, overlay venues + date_stage backdrops, and a second layer of **hidden** `CityBuilder` street activities. Critical hardening themes are lighting (complex WE/sun vs stripped city), amenity art binding, park restaurant zero-size CSG, and interact/outline ownership. Visual PASS blocked — **PENDING VISUAL REVIEW**.
