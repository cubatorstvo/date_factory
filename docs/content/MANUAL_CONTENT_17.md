# MANUAL CONTENT 17 — Scientist & First Clone Inventory

Playable range: overload recognition → Scientist → STAGE_5 / LABORATORY → first clone assignment.

**STOP:** MODULE 18 clone production / rates / mass terminal / President are out of scope.

| ID | Role | Location | Stage | Trait / Competition | XP / Authority | Dating Pool | Marker | Status |
|---|---|---|---|---|---|---|---|---|
| girl_scientist | story girl | city_hub lab gate | STAGE_4 | KIND / DEMANDING | XP 4 | date_pool_cafe_common + date_pool_scientist | StageActorAnchor (`requires_overload_recognized`) | production |
| rival_scientist | story rival | city_hub lab gate | STAGE_4 | SIGMA preferred (+SLAP) | Auth 7 → +3 | — | StageActorAnchor (`requires_overload_recognized`) | production |
| appearance_female_scientist | appearance | — | — | female | — | — | ContentDB | production |
| appearance_male_scientist_rival | appearance | — | — | male | — | — | ContentDB | production |
| appearance_male_first_clone | appearance | laboratory | STAGE_5 | male first-clone visual | — | — | FirstClone preview/representative | production |
| discovery_situation_scientist_lab_gate | discovery | city_hub lab gate | STAGE_4 after recognition | Scientist approaches | — | — | ContentDB | production |
| discovery_approach_scientist_body_count | discovery approach | — | — | Scientist | — | — | ContentDB | production |
| discovery_approach_scientist_buy_body | discovery approach | — | — | Scientist | — | — | ContentDB | production |
| discovery_approach_scientist_ethics_later | discovery approach | — | — | Scientist | — | — | ContentDB | production |
| date_pool_scientist | dating pool | cafe | — | 4 scientist events + cafe fillers | — | — | ContentDB | production |
| date_event_scientist_clone_question | dating event | cafe | — | Scientist-specific | — | date_pool_scientist | ContentDB | production |
| date_event_scientist_failed_test | dating event | cafe | — | Scientist-specific | — | date_pool_scientist | ContentDB | production |
| date_event_scientist_hot_cup | dating event | cafe | — | Scientist-specific | — | date_pool_scientist | ContentDB | production |
| date_event_scientist_napkin_hypothesis | dating event | cafe | — | Scientist-specific | — | date_pool_scientist | ContentDB | production |
| story_point_clone_machine | world marker | laboratory | STAGE_5 | start FirstClone sequence | — | — | scene marker + interactable | production |
| story_point_clone_output / work / date stations | world markers | laboratory | STAGE_5 | preview / assignment poses | — | — | scene markers | production |

## Counts (through MODULE 17)

| Kind | Count |
|---|---|
| Girls | 12 |
| Rivals | 11 |
| Discovery situations | 12 |
| Scientist-specific dating events | 4 |

## Causal chain

```text
DatingOverload.problem_recognized
→ Scientist + rival visible at closed laboratory gate
→ rival defeat + Scientist +5
→ Story STAGE_4 → STAGE_5
→ StoryFeature.LABORATORY
→ FirstClone calibration → physical clone → WORK or DATING
→ GameState aggregate counts = 1
→ rates remain 0
```

## Phone (MODULE 17)

- After recognition, before Scientist done: «Найти Учёную у закрытой лаборатории.»
- STAGE_5 before clone: «Лаборатория открыта. / Создай первого клона.» (no President).
- After `total_clones >= 1`: КЛОНЫ section — Всего / На работе / На свиданиях / Свободных; no money/min or dates/min.

## Out of scope (MODULE 18+)

Second+ clones, passive production, money/min, dates/min, clone upgrades, mass terminal, President content, individual clone defects/QA/memories.
