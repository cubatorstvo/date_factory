# CITY-PROXY-POI-001 — Independent QA

**Task ID:** CITY-PROXY-POI-001-QA  
**Date:** 2026-08-06  
**QA agent:** df-qa-worker (independent; did not trust implementation report)  
**Scope written:** this file + raw logs under `docs/city_proxy_poi/qa/`  
**Code/scenes modified:** none  

## Verdict

**PASS WITH LIMITATIONS**

## Recommendation to Orchestrator

**NOT READY** for full player-route acceptance (no live city approach / prompt / screenshot evidence).  
Architecture + headless binding inventory look solid; live smoke remains the gap the implementer already marked PENDING.

---

## Summary

Re-verified CITY-PROXY-POI-001 with Godot 4.7.1 headless (and a short Vulkan main boot). Official validator reports `VALIDATE_OK` (20 POI roots, 26 unique action_ids including all listed shops/net/rest/cinema, 3 district gates). Deeper probe found **27** `city_poi_interact` Interactables under tenants (includes dual `city_rest` + InternetCafe×3 + Bus×2). `city.tscn` authors **no** loose `InteractionArea` / `action_id` outside PackedScene instances. Multi-tenant pairs expose two distinct world-space actions. Park starts locked (`park_leisure` false); `to_dict`/`from_dict` round-trips district unlock.  

**Not verified in this session:** normal FPS city walk, on-screen prompts (`go_home`, `sit_cafe`, shop opens), control return, park unlock → ParkRestaurant/Cinema interact in play, or any gameplay screenshot. GodotIQ editor bridge play tools failed (`127.0.0.1:6007` connection refused) despite MCP `godotiq_ping` OK.

---

## Steps actually executed

1. Read implementer `BUILD_REPORT.md` / `VALIDATION_REPORT.md` / `POI_REPLACEMENT_GUIDE.md` (treat as claims only).
2. `godotiq_project_summary(detail=brief)` — project OK; autoloads present.
3. Headless: `Godot_v4.7.1-stable_win64_console.exe --headless --path <project> --script res://tools/validate_city_proxy_poi.gd` → `VALIDATE_OK`.
4. Headless deep probes (temp scripts under `tools/_qa_*_tmp.gd`, deleted after run): POI names, per-POI actions, marker inventory, `city_poi_interact` group, ParkGate tree, Clothing/Flower/Gift marker proximity, district save/load.
5. Headless project quit-after 3 and Vulkan main `--quit-after 8` for boot errors.
6. Attempted `godotiq_run(play, main)` / `check_errors` — **failed** (bridge port 6007 refused). No screenshots possible.
7. Grep/`file_context` structural checks on `city.tscn` (instances-only under `POIs`, DistrictGate×3, no authored InteractionArea).

---

## Criterion-by-criterion

### 1. 20 POI roots under CityVisual/POIs
| Status | **PASS** |
|---|---|
| Evidence | Instantiated `city.tscn`: `POIs` child count = **20**. Names: AgencyOffice, Arcade, Bar, BarberShop, Bookstore, BusStopCandy, CafeTwoHearts, Cinema, DuckFeeding, FashionPairJewelryClothing, Gym, HomewareShop, InternetCafe, KaraokeStand, MainBench, ParkBench, ParkRestaurant, PhotoStudio, PlayerHome, RetailPairFlowerGift. Runtime mount in `complex_world._build_city` names the packed city root **`CityVisual`**, so live path is `CityVisual/POIs/*` (packed file root is `City`, not a nested CityVisual node). |
| Reproduction | Headless instantiate city; count `POIs` children. Or play → city → inspect `CityVisual/POIs`. |

### 2. No critical runtime errors on city load
| Status | **PASS** (headless) / **WARNING** (full play route not run) |
|---|---|
| Evidence | Validator + probes: exit 0, no parse/runtime errors while instantiating city + reading Interactables. Main Vulkan boot log (`docs/city_proxy_poi/qa/main_boot_raw.log`) shows engine start, no script errors in captured window (boot likely exited before city spawn). Transient `--script` compile noise on one probe referencing Interactable/`Game` order — not reproduced on clean validate. |
| Reproduction | Run validate script; optional full play into city. |

### 3. Tenant Interactables present for listed action_ids
| Status | **PASS** |
|---|---|
| Evidence | `GROUP_city_poi_interact=27`. Required set all owned (`UNOWNED_FOR_FALLBACK=NONE`). Sample paths: `PlayerHome/.../go_home`, `CafeTwoHearts/.../sit_cafe`, Homeware `open_homeware_shop`, InternetCafe three areas, MainBench `city_rest`, etc. Official validate: `VALIDATE_ACTION_COUNT=26` unique ids (+ Marker-only `sit_park` expected outside tenant group). |
| Reproduction | `validate_city_proxy_poi.gd` or inspect group `city_poi_interact`. |

### 4. Multi-tenant pairs expose two distinct actions
| Status | **PASS** |
|---|---|
| Evidence | RetailPairFlowerGift: `open_flower_shop` @ (17.25,0,5.3) and `open_gift_shop` @ (13.65,0,5.3). FashionPairJewelryClothing: `open_jewelry_shop` @ (4.0,0,5.3) and `open_clothing_shop` @ (6.8,0,5.3). Distinct positions and action_ids. Markers `FlowerEntrance`/`GiftEntrance`/`ClothingEntrance` present and near pair roots. |
| Reproduction | Instantiate city; list InteractionAreas under each pair. |

### 5. District gates present (3)
| Status | **PASS** |
|---|---|
| Evidence | `VALIDATE_GATES=3`. Instances: `Decor/ParkGate` (`park_leisure`), `Decor/AgencyGate` + `Decor/AgencyGateLeisure` (`agency_row`), all `DistrictGate.tscn`, group `district_gate`. ParkGate has BarrierMesh + StaticBody3D + InteractionArea; default `park_leisure` unlocked = **false**. |
| Reproduction | Headless gate walk; or approach ParkGate in play when locked. |

### 6. city.tscn does not author loose POI InteractionAreas outside instances
| Status | **PASS** |
|---|---|
| Evidence | File text: `TSCN_HAS_InteractionArea=false`, `TSCN_HAS_action_id=false`, `TSCN_POI_INSTANCES=20` (`parent="POIs" instance=`). Instantiated tree: `LOOSE_INTERACTION_AREAS=0` outside POIs/gates. Interactables live inside prefab instances only. |
| Reproduction | Search city.tscn for InteractionArea; instantiate and audit. |

### 7. Screenshots / visual play route
| Status | **WARNING** (honest limitation) |
|---|---|
| Evidence | **No screenshots captured.** GodotIQ `run`/`screenshot`/`explore` unavailable (`WinError 1225` to `127.0.0.1:6007`). Cannot open/describe gameplay images. Proxy visual quality, approach blocking, prompt text, and control return **unverified**. |
| Reproduction | Enable GodotIQ addon in editor → play main → Continue → go_outside → approach POIs; capture screenshots. |

### 8. Save/load district unlock persistence
| Status | **PASS** (API smoke) |
|---|---|
| Evidence | Fresh: unlocked=`[main_street]`, park=false. `from_dict({unlocked_districts:[main_street,park_leisure]})` → park=true. `from_dict({unlocked_districts:[main_street]})` → park=false again. `to_dict` emits string list. Note: calling `unlock_district` also sets facility flags; subsequent `from_dict` may re-open park via `try_unlock_park_from_progress()` — pre-existing progress hook, not a POI regression. Full disk save/load via Save UI not exercised. |
| Reproduction | Headless Game.city to_dict/from_dict as above; optional full save slot test in play. |

### 9. Park unlock → ParkRestaurant / Cinema still interact (optional)
| Status | **WARNING** (structure only) |
|---|---|
| Evidence | Prefabs present: ParkRestaurant `sit_restaurant`, Cinema `sit_cinema` under tenants, monitoring=true. Live unlock→approach not run. |
| Reproduction | Unlock park (stage/progress/debug) → walk to restaurant/cinema → confirm prompts. |

### 10. Spot-check Homeware / InternetCafe×3 / MainBench
| Status | **PASS** (inventory) / **WARNING** (no prompt play) |
|---|---|
| Evidence | Homeware `open_homeware_shop`; InternetCafe `city_cafe_job` + `city_cafe_scroll` + `city_coffee` (3 Area3D); MainBench `city_rest`. |
| Reproduction | Approach in play; confirm three distinct net prompts. |

---

## Edge cases checked

| Case | Result | Notes |
|---|---|---|
| Dual `city_rest` (MainBench + ParkBench) | **PASS** (structure) | Both in `city_poi_interact`; ownership dict skips Marker fallback for `city_rest` once any tenant owns it — both benches ship their own Interactables (matches implementer risk note). |
| Missing Flower/Gift/Clothing shop Markers | **PASS** | Correct marker names (`FlowerEntrance`, etc.) all present (`MISSING_MARKERS=NONE`). |
| Fallback would spawn duplicates | **PASS** | All required action_ids owned → fallback adds none. |
| Park locked at default progress | **PASS** | park=false until unlock; ParkGate StaticBody present. |

---

## Unmet / limited criteria

1. **Live normal-route city play** (boot → apartment → go_outside → approach POIs) — not executed.
2. **On-screen prompts / control return / repeated use** — not executed.
3. **Gameplay screenshots** — none (bridge down).
4. **Full Save UI slot** for districts — only `Game.city` dict API smoke.
5. **Post-unlock park POI interact in play** — not executed.

---

## Commands + raw engine log excerpts

### Official validator (PASS)

```text
Godot Engine v4.7.1.stable.official.a13da4feb - https://godotengine.org
[GodotIQ] Runtime _ready() — debugger active: false
[GodotIQ] Debugger not active, freeing runtime
VALIDATE_POI_COUNT=20
VALIDATE_ACTION_COUNT=26
VALIDATE_ACTIONS=city_bar_drink,city_bus_info,city_buy_gift,city_cafe_job,city_cafe_scroll,city_coffee,city_gym_pass,city_karaoke,city_park_fun,city_rest,city_workout,go_home,open_agency_board,open_arcade,open_barber,open_bookstore,open_clothing_shop,open_flower_shop,open_gift_shop,open_homeware_shop,open_jewelry_shop,open_photo_studio,sit_arcade,sit_cafe,sit_cinema,sit_restaurant
VALIDATE_GATES=3
VALIDATE_OK
```

Command:

```text
Godot_v4.7.1-stable_win64_console.exe --headless --path C:\Users\User\Documents\GodotProjects\date_factory --script res://tools/validate_city_proxy_poi.gd
```

Log copy: `docs/city_proxy_poi/qa/validate_city_proxy_poi_raw.log`

### Deep probe excerpts (independent)

```text
POIS_PARENT=City
POI_NAMES=AgencyOffice,...,RetailPairFlowerGift  # 20
GROUP_city_poi_interact=27
HAS_flower=true HAS_gift=true
HAS_jewelry=true HAS_clothing=true
HAS_net3=true
PARK_UNLOCKED_DEFAULT=false
MISSING_MARKERS=NONE
UNOWNED_FOR_FALLBACK=NONE
TSCN_HAS_InteractionArea=false
TSCN_POI_INSTANCES=20
LOOSE_INTERACTION_AREAS=0
GATE=ParkGate district=park_leisure
GATE=AgencyGate district=agency_row
GATE=AgencyGateLeisure district=agency_row
```

### Main Vulkan boot (partial; not city FPS)

```text
Godot Engine v4.7.1.stable.official.a13da4feb - https://godotengine.org
Vulkan 1.4.303 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 4060 Laptop GPU
[GodotIQ] Runtime _ready() — debugger active: false
[GodotIQ] Debugger not active, freeing runtime
```

Log: `docs/city_proxy_poi/qa/main_boot_raw.log`  
(stderr empty: `docs/city_proxy_poi/qa/main_boot_err.log`)

### GodotIQ play attempt

```text
Failed to connect to 127.0.0.1:6007: [WinError 1225] Удаленный компьютер отклонил это сетевое подключение
hint: Enable the GodotIQ addon in Godot editor and ensure it is running.
```

---

## Screenshot paths + what was seen

| Path | Content |
|---|---|
| *(none)* | No gameplay/editor screenshots captured this session. Visual POI appearance, prompt HUD, and approachability **not** visually confirmed. Do not treat implementer docs or filenames as visual evidence. |

---

## Blocking issues

1. **No independent live player-route smoke** (GodotIQ play bridge down). Per project quality gates, code/structure ≠ ready gameplay. Blocks **READY**.

## Non-blocking issues

1. Packed scene root is `City` (not a nested `CityVisual` node); `CityVisual` is the mount name from `complex_world` — criteria wording is OK at runtime, slightly confusing in file tree.
2. LotBounds debug visibility in debug builds (implementer-noted) — not re-checked visually.
3. Large cinema lot bleed risk (implementer-noted) — not re-checked spatially in play.
4. Full Save UI not run; only city API dict round-trip.

---

## Overall status

**PASS WITH LIMITATIONS**

Structural PASS criteria for the proxy POI architecture refactor are met under headless re-verification. Interactive city route, prompts, and screenshots remain **unverified** → Orchestrator should treat gameplay acceptance as **NOT READY** until one normal-route play session confirms approaches and prompts (editor GodotIQ or manual).
