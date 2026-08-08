# VISUAL BOOTSTRAP — Final Report

**Date:** 2026-08-09  
**Orchestrator verdict:** **READY**  
**Independent QA:** [Stage G](docs/agent/qa/VISUAL_BOOTSTRAP_STAGE_G_QA.md) — PASS (50/0)

---

## 1. DONOR SOURCES USED

| Location | Donor scene | Notes |
|---|---|---|
| City | `scenes/world/city/city.tscn` + `scenes/art/city/**` POIs | Instanced as `Geometry/DonorCity` in `city_hub` |
| Room | `scenes/world/vertical_slice/apartment.tscn` | Instanced as `Geometry/DonorApartment` |
| Cafe | `scenes/world/vertical_slice/restaurant.tscn` | Instanced as `Geometry/DonorCafe`; **location id stays `cafe`** (D-VB-03) |

Facade POI `CafeTwoHearts` travels with city art (approach only).

---

## 2. ASSET PACKS USED

| Zone | Packs |
|---|---|
| City | PACK_001 Downtown MegaKit (+ selective sushi/interior props via POIs) |
| Room | PACK_018 House Interior, PACK_017 Food, drinkware |
| Cafe | Donor venue deps → sushi_restaurant meshes (PACK_016 as scene closure only; D-VB-04) |
| Mine | PACK_002 Kenney Factory |
| Lab | PACK_015 Sci-Fi Essentials (+ Kenney corridor accents). **PACK_013 absent** |
| Late | PACK_002 + PACK_015 |
| Characters | PACK_021 hero_base, PACK_019 women_modular variants, PACK_020 UAL |

Not used: PACK_014 music. PACK_016 not expanded beyond donor cafe/city deps.

---

## 3. COPIED RESOURCES

| Local path | Role |
|---|---|
| `assets/environment/city/downtown_megakit/` | City meshes |
| `assets/environment/interior/` | Apartment interior |
| `assets/environment/restaurant/sushi_restaurant/` | Cafe venue deps |
| `assets/environment/factory/kenney_factory/` | Mine / late |
| `assets/environment/lab/scifi_essentials/` | Lab / late |
| `assets/props/food/` | Apartment props |
| `assets/characters/**`, `assets/animation/universal_library/**` | Expanded character/UAL closures |
| `world/art/donor_import/{city,apartment,cafe}/` | Rewritten local art scenes |
| `characters/female/female_{formal,suit,worker,punk}_visual.tscn` | Variant wrappers |

**Runtime donor dependency:** none (Stage G scan of `world/`, `assets/`, `characters/`, `data/` = 0 hits for `date_factory_legacy`).

---

## 4. TECHNICAL FIXES APPLIED

- Path rewrites `res://scenes/art/...` → `res://world/art/donor_import/...`
- Legacy Interactable → stub on city POIs; travel via current `WorldTransition`
- `apartment_place_setting.gd` stubbed (no legacy `Game`)
- Cube Geometry hidden; donor/pack visuals instanced
- Marker remaps onto donor landmarks (spawn, doors, DateVenue, SalaryStation, etc.)
- Lighting boosts (city ambient/exposure; lab cool; production OmniLights)
- Debug BoxMeshes hidden on apartment/cafe interactables where practical
- Female appearance `visual_scene` remaps for city/cafe variety

---

## 5. SCREENSHOT SET

| Set | Count | Path |
|---|---:|---|
| Legacy (A1–A3) | 22 | `tmp/visual_bootstrap_review/legacy/` |
| Current (B–F) | 43 | `tmp/visual_bootstrap_review/current/` |

**Branch:** `visual-review/bootstrap-20260809` @ `0b09f0b`  
**Source commit (main):** `80e972e`  
**Screenshot path on review branch:** `_review/visual_bootstrap/{legacy,current}/`  
*(Working copies also under `tmp/visual_bootstrap_review/` — not committed on main.)*

---

## 6. REMAINING ISSUES

- City: some white/CSG placeholder volumes + megakit trim red-edge artifacts (D-VB-09)
- Lab dating booth shells still tinted BoxMeshes — PACK_013 not on disk (D-VB-10)
- Sushi pack LICENSE.txt missing in donor tree (documented; not invented)
- Cafe/city NPC density can look cluttered in review frames
- DateVenue proven interactable via API; full dating session not forced in Stage G
- Not an art-polish pass — bootstrap only

---

## Criteria of Done

| Criterion | Status |
|---|---|
| Donor city / room / cafe transferred | YES |
| Cafe kept as cafe (not restaurant location) | YES |
| Local copies; no donor runtime deps | YES |
| Mine / lab / late non-cube bases | YES |
| Minimal character visual base | YES |
| Markers / early routes / DateVenue | YES (Stage G) |
| Legacy + current screenshots | YES 22+43 |
| Source on main; PNGs on review branch | YES |
| Stop (no unsolicited polish) | YES |
