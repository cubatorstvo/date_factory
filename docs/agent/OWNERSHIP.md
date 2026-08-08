# File ownership — MODULE 20 Late Game Expansion

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M20_A_CONTENT | content | President girl/rival/appearances/discovery/date_pool+6 events/farewell, `content_catalog.tres`, content test count asserts if needed | scenes, LateGameExpansion, MODULE 21 final girl | done |
| M20_B_GATES | gameplay | `stage_actor_anchor.gd` (`requires_first_clone_created`), `girl_discovery.gd` President prereq, `girl_actor.gd` feedback branch, `phone_journal.gd` STAGE_5/6/FINALE, related self-tests | production_area.tscn, late_game formulas, MODULE 21 | done |
| M20_C_LATE_CORE | gameplay | `game/late_game/**` (new), `game_state.gd` Reach/global levels, narrow `clone_incremental/**` multiplier seam, `project.godot` LateGameExpansion after CloneIncremental | city_hub/production/final .tscn, President .tres, MODULE 21 | done |
| M20_D_PROD_SCENE | scene | `production_area.tscn` only | city_hub, laboratory, final_location | done |
| M20_E_WORLD_MARKERS | scene | `city_hub.tscn` President anchors + Stage6 sign; `laboratory.tscn` corridor wording only; `final_location.tscn` FinalSignalBeacon | production_area.tscn, late_game core | done |
| M20_F_VIZ_LABEL | gameplay | `game/clone_visualization/**` external Work/Dating/Free label + M19 tests | laboratory geometry | done |
| M20_G_DOCS | content | PROJECT_STRUCTURE, TECHNICAL_DECISIONS, gdd 07/08 | runtime | done |
| M20_H_QA | qa | `tmp/m20_qa/**`, `docs/agent/qa/M20_QA.md` | product sources | done |

## Product decisions
1. Use existing Story STAGE_5→6→FINALE; no parallel stage machine.
2. President only after `total_clones >= 1` (anchor + discovery STORY_PREREQUISITE).
3. LateGameExpansion owns Reach + global ×2^n multipliers; CloneIncremental remains economy owner.
4. Reach += 2 per late XP in STAGE_6 only; Reach 100 → `Story.complete_world_expansion()`.
5. No countries/airports/logistics simulation — presentation props only.
6. STOP at FINALE + FINAL_DATE + signal — no `girl_final_target` / MODULE 21 date.
