# File ownership — Visual Bootstrap Corrective (single-base characters)

**Status:** complete (READY)  
**Spec:** `VISUAL_BOOTSTRAP_CORRECTIVE_SINGLE_BASE_CHARACTERS_RU.md`  
**Date:** 2026-08-09  
**Main:** `b59c3c9` · **Review:** `visual-review/corrective-20260809` @ `05c2f0a`

| Task id | Agent | Writable paths | Read-only dependencies | Forbidden | Status |
|---|---|---|---|---|---|
| VC-DOCS | Orchestrator | `docs/agent/**`, `docs/ASSET_LICENSES.md`, `docs/THIRD_PARTY_ASSETS.md` | donor RO, TZ | gameplay redesign | complete |
| VC-CHARS | df-gameplay-worker | characters + appearances + variant controller | PACK_021 RO | PACK_019 delete (later) | complete |
| VC-CITY | df-scene-worker | `city_hub.tscn` | donor city RO | other locations | complete |
| VC-APT | df-scene-worker | `apartment.tscn` + donor_import apt | donor apt RO | other locations | complete |
| VC-CAFE | df-scene-worker | `cafe.tscn` + `restaurant.tscn` | donor restaurant RO | other locations | complete |
| VC-MINE | df-scene-worker | `salary_mine.tscn` | kenney_factory RO | other locations | complete |
| VC-LAB | df-scene-worker | `laboratory.tscn` | scifi_essentials RO | invent PACK_013 | complete |
| VC-LATE | df-scene-worker | `production_area.tscn` | factory + scifi RO | other locations | complete |
| VC-PACK019-DEL | Orchestrator | delete `assets/characters/women_modular/**` | refs=0 gate | donor | complete |
| VC-CHARS-FIX | df-gameplay-worker | BoneAttachment external_skeleton bind | QA FAIL | — | complete |
| VC-QA / VC-REVIEW | df-qa-worker | review PNGs + QA md | full game RO | polish | complete |

## Serialization (historical)

Wave1 CHARS∥CITY∥APT → Wave2 CAFE∥MINE∥LAB → Wave3 LATE + PACK019 → Wave4 tests/push/review/QA.  
One writer per `.tscn`. Donor READ-ONLY forever.
