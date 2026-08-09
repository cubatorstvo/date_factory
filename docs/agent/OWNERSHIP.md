# File ownership — Visual Art Pass 01 (Characters + City POI + NPC presentation)

**Status:** in progress  
**Spec:** `VISUAL_ART_PASS_01_CHARACTERS_CITY_RU.md`  
**Date:** 2026-08-09  
**Base:** main @ `4b848b8` (corrective READY)

| Task id | Agent | Writable paths | Forbidden | Status |
|---|---|---|---|---|
| AP1-DOCS | Orchestrator | `docs/agent/**`, licenses if needed | gameplay redesign | active |
| AP1-CHARS | df-gameplay-worker | `characters/male/**`, `characters/female/**`, `characters/framework/character_variant_controller.gd`, `characters/framework/character_actor.gd` (minimal), `characters/test/**`, `data/content/appearances/**` (hair_variant remaps 0–4 only) | locations, PACK_019, new bases | pending |
| AP1-CITY-POI | df-scene-worker | `world/art/donor_import/city/poi/buildings/*.tscn` (VisualRoot/Collision only), optionally `CityPOIBuilding.gd` LotBounds harden | city_hub layout, POI root transforms, district gate logic | pending |
| AP1-NPC | df-gameplay-worker | `world/locations/city_hub/city_hub.tscn` (NpcSpawns presentation only), `world/locations/cafe/cafe.tscn` (NpcSpawns presentation only), new presentation helper under `world/` or `characters/` if needed | cafe geometry/lights, apartment/mine/lab/late art | pending |
| AP1-QA | df-qa-worker | `tmp/art_pass_01/**`, review branch PNGs, QA md | art redesign | pending |

## Serialization
1. Parallel Wave1: **AP1-CHARS** ∥ **AP1-CITY-POI** ∥ **AP1-NPC** (no shared files).
2. Then RC tests → push main → `visual-review/art-pass-01-20260809` screenshots → QA.
3. One writer per `.tscn`. Donor READ-ONLY.
