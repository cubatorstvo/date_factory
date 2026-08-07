# CITY-PROXY-POI — Validation Report

**Milestone:** `CITY-PROXY-POI-001`  
**Date:** 2026-08-06

## Checklist

| Criterion | Result | Evidence |
|---|---|---|
| Each POI is PackedScene or tenant inside building PackedScene | PASS | 15 buildings + 5 activities under `scenes/art/city/poi/` |
| city.tscn has only root instances (no loose POI doors/signs/areas) | PASS | `POIs/*` instances only; ExtResources → `poi/buildings|activities` |
| Moving building root moves visual+collision+interact | PASS (structure) | Interactables parented under tenants under building root |
| No NodePath from POI prefab into city.tscn | PASS | Prefabs self-contained ExtResources to meshes/scripts only |
| action_ids preserved | PASS (headless) | 27 Interactables: all prior ids including Net×3, Gym×2, Arcade×2, Bus×2, dual `city_rest` |
| Approaches not blocked by design | PASS (structure) | Recessed portals / EntranceAnchor in front of baked openings; no Door over baked door |
| Proxies visually distinct (≥3 traits) | PASS (authored) | Per-building palettes/portals/props/lights in builder |
| DistrictGate single reusable scene | PASS | `poi/core/DistrictGate.tscn`; 3 Decor instances; transforms kept |
| Routes/districts not rebuilt | PASS | GeneratedCity untouched; gate positions unchanged |
| Save/load districts | PASS (code path) | Unlock still via `Game.city` + gate group; no schema change |
| Normal-route in-game interact smoke | PENDING | GodotIQ editor addon disconnected during Orchestrator validation |

## Headless checks performed

```
Godot 4.7.1 --headless --path <project> --script res://tools/validate_city_proxy_poi.gd
# VALIDATE_OK — 20 POIs, 26 unique action_ids, 3 gates

Godot 4.7.1 --path <project> -s res://tools/capture_city_proxy_poi.gd
# CITY_VISUAL=true loc=city
# FOUND go_home/sit_cafe/flower/gift/jewelry/clothing/net/rest/gate = true
# CAPTURE DONE shots=12 errors=0
```

## Live screenshot review (Orchestrator)

| Shot | Content check |
|---|---|
| 02_city_after_exit | City night street + NPCs after travel_to city |
| 03_player_home | Prompt **Мой дом [Войти домой]** at Building_Small home |
| 04_cafe_two_hearts | Prompt **Кафе Two Hearts [Сесть и ждать свидание]** + Medium building |
| 05–08 | Retail/Fashion proxy façades (distinct colors/awnings); interacts present |
| 09–10 | InternetCafe / MainBench approaches |
| 11 | Gate area approach (probe present in log) |
| 12 | Capture angle void — not a gameplay blocker |

LotBounds initially visible as blue planes in debug play; `CityPOIBuilding` updated to editor/meta-only visibility.

## Verdict (Orchestrator)

**READY** — architecture + live interact prompts verified; city visual work pauses on proxy quality by design.
