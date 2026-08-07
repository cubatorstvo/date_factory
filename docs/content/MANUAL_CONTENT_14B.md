# MANUAL CONTENT 14B — Editor & Pre-Media Inventory

Playable range: `PROLOGUE → … → STAGE_3 → Editor → STAGE_4 / MEDIA_ATTENTION` (photo-session marker only; no media runtime).

**STOP:** MODULE 15 media feed / photoshoot / Scientist content are out of scope.

| ID | Role | Location | Stage | Trait / Competition | XP / Authority requirement | Dating Pool | Marker | Status |
|---|---|---|---|---|---|---|---|---|
| girl_magazine_editor | story girl | appearance_space (studio) | STAGE_3 | STRANGE / SCANDALOUS | XP 3 | date_pool_cafe_common + date_pool_magazine_editor | StageActorAnchor | production |
| girl_public_sculpture | ordinary girl | city_hub public | ≥XP (+ PUBLIC_CITY_ACCESS) | STRANGE / CONSISTENT | XP 2 | date_pool_cafe_common | NPC marker | production |
| girl_cafe_receipt_notes | ordinary girl | cafe | ≥XP | KIND / DEMANDING | XP 2 | date_pool_cafe_common | NPC marker | production |
| girl_appearance_flash | ordinary girl | appearance_space | ≥XP | STATUS / SCANDALOUS | XP 3 | date_pool_cafe_common | NPC marker | production |
| rival_magazine_editor | story rival | appearance_space (studio) | STAGE_3 | MONEY preferred (+DANCE) | Auth 4 → +3 | — | StageActorAnchor | production |
| rival_public_coat | ordinary rival | city_hub public | ≥Auth (+ PUBLIC_CITY_ACCESS) | DANCE (+SLAP) | Auth 3 → +1 | — | NPC marker | production |
| rival_public_watch | ordinary rival | city_hub public | ≥Auth (+ PUBLIC_CITY_ACCESS) | MONEY (+DANCE) | Auth 4 → +1 | — | NPC marker | production |
| rival_appearance_tripod | ordinary rival | appearance_space | ≥Auth | SIGMA (+SLAP) | Auth 4 → +1 | — | NPC marker | production |
| date_pool_magazine_editor | dating pool | cafe | — | 4 editor events + cafe fillers | — | — | ContentDB | production |
| date_event_editor_publishable_failure | dating event | cafe | — | Editor-specific | — | date_pool_magazine_editor | ContentDB | production |
| date_event_editor_headline | dating event | cafe | — | Editor-specific | — | date_pool_magazine_editor | ContentDB | production |
| date_event_editor_public_argument | dating event | cafe | — | Editor-specific (public CONFLICT route) | — | date_pool_magazine_editor | ContentDB | production |
| date_event_editor_bad_photo | dating event | cafe | — | Editor-specific | — | date_pool_magazine_editor | ContentDB | production |
| discovery_situation_magazine_editor_shoot | discovery | appearance_space | STAGE_3 | Editor shoot approaches | — | — | ContentDB | production |
| discovery_situation_public_sculpture | discovery | city public | — | ordinary | — | — | ContentDB | production |
| discovery_situation_cafe_receipt_notes | discovery | cafe | — | ordinary | — | — | ContentDB | production |
| discovery_situation_appearance_flash | discovery | appearance_space | — | ordinary | — | — | ContentDB | production |
| appearance_female_magazine_editor | appearance | — | — | female | — | — | ContentDB | production |
| appearance_female_public_sculpture | appearance | — | — | female | — | — | ContentDB | production |
| appearance_female_cafe_receipt_notes | appearance | — | — | female | — | — | ContentDB | production |
| appearance_female_appearance_flash | appearance | — | — | female | — | — | ContentDB | production |
| appearance_male_magazine_editor_rival | appearance | — | — | male | — | — | ContentDB | production |
| appearance_male_public_coat | appearance | — | — | male | — | — | ContentDB | production |
| appearance_male_public_watch | appearance | — | — | male | — | — | ContentDB | production |
| appearance_male_appearance_tripod | appearance | — | — | male | — | — | ContentDB | production |
| story_point_editor_photo_session | world marker | appearance_space | STAGE_4 cue | photo invite only | — | — | scene marker | present, does not launch |

## Counts (14A + 14B)

| Kind | Count |
|---|---|
| Girls | 11 |
| Rivals | 10 |
| Appearance profiles | 23 (includes 8 new 14B profiles) |
| Discovery situations | 11 |
| Dating pools | ≥6 (adds `date_pool_magazine_editor`) |
| Editor-specific dating events | 4 |

## Handoff (STAGE_4)

- `StoryFeature.MEDIA_ATTENTION == true`
- Phone Story shows media handoff (`Медийность` / `Фотосессия у Редактора`)
- `ContentDB.try_get_girl(girl_scientist)` / `try_get_rival(rival_scientist)` return null (no crash)

## Out of scope (MODULE 15+)

Photoshoot runtime, social feed, Attention, publishing, incoming dates, Dating Overload, Scientist / Laboratory story line.
