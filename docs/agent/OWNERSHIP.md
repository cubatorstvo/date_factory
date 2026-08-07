# File ownership — MODULE 14A Early Vertical Slice

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M14A_A_FRAMEWORK | df-gameplay-worker | `data/definitions/girl_definition.gd`, `data/catalog/content_db.gd` (date binding validation only), `game/rivals/rival_actor.gd`, `game/girls/girl_actor.gd` (story lock feedback), `game/world_actors/stage_actor_anchor.gd` (or `world/actors/`), `game/dating/date_venue_interactable.gd`, `game/progression/progression_interactable.gd` (+ minimal modal UI script under `ui/progression/` if needed), optional `game/rivals/rival_actor.tscn` | `data/content/**` bulk catalog, location `.tscn` (except if tiny fixture for script test), PhoneJournal, MODULE 14B/15 | done |
| M14A_B_CONTENT | df-content-worker | `data/content/girls/**`, `rivals/**`, `appearances/**`, `discovery/**`, `dating/**` (events/pools/greetings/farewells), `data/catalog/content_catalog.tres` | gameplay scripts, `.tscn` locations, PhoneJournal | done |
| M14A_C_SCENES | df-scene-worker | location `.tscn`: apartment, city_hub, cafe, gym, appearance_space — anchors, DateVenue, ProgressionInteractable, ordinary actor markers only | `project.godot`, ContentDB formulas, PhoneJournal, MODULE 14B girls | done |
| M14A_D_PHONE_DOCS_TESTS | df-gameplay-worker | `ui/phone/phone_journal.gd`, docs listed in §48, `docs/content/MANUAL_CONTENT_14A.md`, `game/**/test/**` new 14A integration tests | Editor/Scientist content, Media | done |
| M14A_E_QA | df-qa-worker | evidence only | product sources | done |

## Product decisions (Orchestrator)

1. **Pool IDs:** ContentDB requires `date_pool_*`. Map spec names:
   - `dating_pool_apartment_common` > `date_pool_apartment_common`
   - `dating_pool_neighbor` > `date_pool_neighbor`
   - `dating_pool_cafe_common` > `date_pool_cafe_common`
   - `dating_pool_actress` > `date_pool_actress`
   - `dating_pool_mine_boss` > `date_pool_mine_boss`
2. Phone Story API: use `Story.get_current_progress()` (not get_current_stage_progress).
3. Appearance: derive from `appearance_female_base` / `appearance_male_base` with clothing/hair variation only.
4. No quest/dialogue engine; only StageActorAnchor, DateVenueInteractable, ProgressionInteractable.
5. STOP after 14A — do not start 14B.
