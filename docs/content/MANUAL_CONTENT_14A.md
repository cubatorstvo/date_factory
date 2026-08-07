# MANUAL CONTENT 14A — Early Vertical Slice Inventory

Playable range: `PROLOGUE → STAGE_1 → STAGE_2 → STAGE_3` (Salary Mine unlock).

**Pool naming:** ContentDB requires `date_pool_*`. Spec draft names `dating_pool_*` map 1:1 to these IDs.

| ID | Role | Location | Stage | Trait / Competition | XP / Authority requirement | Dating Pool | Marker | Status |
|---|---|---|---|---|---|---|---|---|
| girl_neighbor | story girl | apartment | PROLOGUE | KIND / CONSISTENT | XP 0 | date_pool_apartment_common + date_pool_neighbor | StageActorAnchor | production |
| girl_actress | story girl | appearance_space | STAGE_1 | STATUS / DEMANDING | XP 1 | date_pool_cafe_common + date_pool_actress | StageActorAnchor | production |
| girl_mine_boss | story girl | city_hub (mine entrance) | STAGE_2 | THRILL / CONSISTENT | XP 2 | date_pool_cafe_common + date_pool_mine_boss | StageActorAnchor | production |
| girl_city_bicycle | ordinary girl | city_hub | any (≥XP) | KIND / VARIETY | XP 0 | date_pool_cafe_common | NPC marker | production |
| girl_cafe_laptop | ordinary girl | cafe | any (≥XP) | STATUS / CONSISTENT | XP 1 | date_pool_cafe_common | NPC marker | production |
| girl_gym_chalk | ordinary girl | gym | any (≥XP) | THRILL / SCANDALOUS | XP 1 | date_pool_cafe_common | NPC marker | production |
| girl_appearance_ritual | ordinary girl | appearance_space | any (≥XP) | STRANGE / VARIETY | XP 2 | date_pool_cafe_common | NPC marker | production |
| rival_actress | story rival | appearance_space | STAGE_1 | DANCE (+SLAP) | Auth 0 → +2 | — | StageActorAnchor | production |
| rival_mine_boss | story rival | city_hub (mine entrance) | STAGE_2 | SLAP (+DANCE) | Auth 2 → +2 | — | StageActorAnchor | production |
| rival_city_tracksuit | ordinary rival | city_hub | any | SLAP (+DANCE) | Auth 0 → +1 | — | NPC marker | production |
| rival_city_silent | ordinary rival | city public segment | any | SIGMA (+SLAP) | Auth 3 → +1 | — | NPC marker | production |
| rival_cafe_receipt | ordinary rival | cafe | any | MONEY (+DANCE) | Auth 2 → +1 | — | NPC marker | production |
| rival_gym_mirror | ordinary rival | gym | any | DANCE (+SLAP) | Auth 1 → +1 | — | NPC marker | production |
| date_pool_apartment_common | dating pool | apartment | — | 6+ apartment events | — | — | ContentDB | production |
| date_pool_neighbor | dating pool | apartment | — | neighbor-themed extras | — | — | ContentDB | production |
| date_pool_cafe_common | dating pool | cafe | — | 12 cafe events (4/cat) | — | — | ContentDB | production |
| date_pool_actress | dating pool | cafe | — | actress-themed extras | — | — | ContentDB | production |
| date_pool_mine_boss | dating pool | cafe | — | mine-boss-themed extras | — | — | ContentDB | production |

## Counts (14A)

| Kind | Count |
|---|---|
| Girls | 7 |
| Rivals | 6 |
| Appearance profiles | 13 (7 female + 6 male) |
| Discovery situations | 7 |
| Dating events | apartment ≥6 + cafe ≥12 + story extras |
| Greetings | 4 |
| Farewells | 1 (`dating_farewell_early_common`) |

## Out of scope (14B+)

Editor, Scientist, President, Media feed, photos, incoming dates, Dating Overload, clones.
