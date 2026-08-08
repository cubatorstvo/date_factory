# File ownership — Visual Bootstrap Corrective (single-base characters)

**Status:** in progress  
**Spec:** `VISUAL_BOOTSTRAP_CORRECTIVE_SINGLE_BASE_CHARACTERS_RU.md`  
**Date:** 2026-08-09

| Task id | Agent | Writable paths | Read-only dependencies | Forbidden | Status |
|---|---|---|---|---|---|
| VC-DOCS | Orchestrator | `docs/agent/OWNERSHIP.md`, `docs/agent/ACCEPTANCE.md`, `docs/agent/DECISIONS.md`, `docs/ASSET_LICENSES.md`, `docs/THIRD_PARTY_ASSETS.md`, `docs/agent/qa/VISUAL_BOOTSTRAP_CORRECTIVE_*.md` | donor RO, TZ | gameplay / location redesign | active |
| VC-CHARS | df-gameplay-worker | `characters/male/**`, `characters/female/**`, `characters/framework/character_variant_controller.gd` (+uid), `characters/framework/character_actor.gd`, `characters/framework/character_actor.tscn` (only if needed), `characters/test/**` (presentation test), `data/definitions/appearance_profile_definition.gd`, `data/content/appearances/**`, `data/content/animation_profiles/**` (female→UAL if needed), `assets/animation/universal_library/libraries/UAL_CLIP_MAP.json` (women_path only) | PACK_021 hero_base RO meshes, CharacterFactory RO, UAL libs RO | girl_actor/rival_actor, player.tscn, dating/story/balance, `women_modular` delete (later), location `.tscn` except none | complete |
| VC-CITY | df-scene-worker | `world/locations/city_hub/city_hub.tscn`, `world/art/donor_import/city/**` (env/light/material parity only) | donor city RO, downtown_megakit RO | other locations, gameplay scripts, layout redesign | complete |
| VC-APT | df-scene-worker | `world/locations/apartment/apartment.tscn`, `world/art/donor_import/apartment/**` (env/light only) | donor apt RO, house_interior RO | other locations, gameplay semantics | complete |
| VC-CAFE | df-scene-worker | `world/locations/cafe/cafe.tscn`, `world/art/donor_import/cafe/**` (incl. strip PACK_019 NPC) | donor restaurant RO | other locations; must stay location id `cafe` | active |
| VC-MINE | df-scene-worker | `world/locations/salary_mine/salary_mine.tscn` | kenney_factory RO | other locations | active |
| VC-LAB | df-scene-worker | `world/locations/laboratory/laboratory.tscn` | scifi_essentials RO | other locations; no invent PACK_013 walls | active |
| VC-LATE | df-scene-worker | `world/locations/production_area/production_area.tscn` | factory + scifi RO | other locations | pending |
| VC-PACK019-DEL | df-asset-worker | delete `assets/characters/women_modular/**`; unused wrappers if any; docs pack notes via Orchestrator | after VC-CHARS+VC-CAFE refs=0 | donor, gameplay | pending |
| VC-QA | df-qa-worker | `tmp/visual_corrective/**`, `tmp/vc_*`, `docs/agent/qa/VISUAL_BOOTSTRAP_CORRECTIVE_QA.md` | full game RO | product redesign | pending |
| VC-REVIEW | Orchestrator | branch `visual-review/corrective-20260809` PNGs only | source on main first | PNGs on main | pending |

## Serialization

1. Wave1 parallel: **VC-CHARS**, **VC-CITY**, **VC-APT** (no shared files).
2. Wave2 parallel: **VC-CAFE**, **VC-MINE**, **VC-LAB**.
3. Wave3: **VC-LATE** then **VC-PACK019-DEL** (only if grep refs=0).
4. Wave4: RC tests → push source main → **VC-REVIEW** screenshots → **VC-QA**.
5. One writer per `.tscn` / shared `.gd`.
6. Donor `../date_factory_legacy` READ-ONLY forever.
