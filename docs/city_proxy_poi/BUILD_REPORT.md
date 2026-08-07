# CITY-PROXY-POI — Build Report

**Milestone:** `CITY-PROXY-POI-001`  
**Date:** 2026-08-06  
**Status:** Architecture + proxy scenes delivered; city visual work pauses after validation.

## Goal

Temporary but architecturally correct city POIs: every POI is a PackedScene (or tenant inside a building) with a final functional contract. Proxy graphics are allowed. Paid Downtown MegaKit audit is stopped.

## Decisions (Orchestrator)

See `docs/agent/DECISIONS.md` → **DEC-004**.

- Landmark shells: PlayerHome = `Building_Small_1`, CafeTwoHearts = `Building_Medium_2_001`, Cinema = `Building_Large_2`.
- Multi-tenant: `RetailPairFlowerGift`, `FashionPairJewelryClothing` only.
- Interactions authored inside tenants; Markers kept for spawn/picnic/camera.
- DistrictGate canonical at `scenes/art/city/poi/core/`.

## Created

### Core
| Path | Role |
|---|---|
| `scenes/art/city/poi/core/CityPOIBuilding.gd` | Building shell + lot + replacement rule |
| `scenes/art/city/poi/core/CityPOITenant.gd` | Tenant contract + Interactable registration |
| `scenes/art/city/poi/core/DistrictGate.tscn` | Reusable district barrier |
| `scenes/art/city/poi/core/district_gate.gd` | Exports: district_id, locked_text, gate_width/height, alphas, fade |

### Buildings (`scenes/art/city/poi/buildings/`)
PlayerHome, CafeTwoHearts, Cinema, RetailPairFlowerGift, FashionPairJewelryClothing, HomewareShop, InternetCafe, Bookstore, Gym, PhotoStudio, BarberShop, AgencyOffice, Arcade, Bar, ParkRestaurant

### Activities (`scenes/art/city/poi/activities/`)
MainBench, ParkBench, DuckFeeding, KaraokeStand, BusStopCandy

### Tooling
`tools/build_city_proxy_poi.gd` — generator used for consistent packing.

### City rewire
`scenes/world/city/city.tscn`:
- `POIs/` holds only root PackedScene instances (20).
- `Buildings/` empty container retained.
- Decor gates → `poi/core/DistrictGate.tscn` (world transforms unchanged).
- Entrance Markers synced for multi-tenant consolidation.

### Binding
`scenes/world/complex_world.gd`: prefers `city_poi_interact`; Marker FALLBACK if tenant interact missing; `sit_park` stays on picnic Marker.

## Placement notes

| Instance | Origin | Notes |
|---|---|---|
| RetailPairFlowerGift | (15.45, 0, 6.35) | Midpoint of former Flower+Gift |
| FashionPairJewelryClothing | (5.4, 0, 6.35) | Jewelry pose; Clothing relocated into pair |
| Others | Prior Stage5 transforms | Routes/districts not rebuilt |

## Differentiation (proxy)

Proxies use BoxMesh + CSG portals/awnings/roofs + distinct GF colors, lights, and identity props. Ready landmarks use free `Building_*` without Door meshes glued over baked openings.

## Out of scope (paused)

City décor polish, final lighting, walk-in interiors, modular architecture, new/paid assets, district/route rebuilds.

## Known limitations

- GodotIQ interactive play was intermittent during build (editor bridge). Headless boot + packed-scene validation used instead for structure.
- Independent QA must confirm in-game interact route + screenshots.
- Legacy `scenes/art/city/prefabs/*` remain as reference; city no longer instances them for POIs.
