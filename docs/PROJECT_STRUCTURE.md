# PROJECT STRUCTURE

Фактическая структура после **MODULE 19 — Physical Clone Visualization**.  
Godot 4.7 · Forward Plus · main scene: `res://main.tscn` → apartment via autoload `World`

## Top-level (существует сейчас)

| Path | Назначение | Можно | Нельзя |
|---|---|---|---|
| `addons/` | Editor/tool plugins | GodotIQ и будущие tooling plugins | Gameplay systems |
| `assets/` | Импортируемые визуальные ресурсы | модели, текстуры, материалы, fonts, props, animation libraries | Gameplay scripts / domain logic |
| `characters/` | Player + Character Framework | `framework/`, `male/`, `female/`, `player/`, `test/` | Dating/Rival/AI domain systems |
| `core/` | Техническая инфраструктура | debug helpers, bootstrap → World apartment, Interactable contract | Game managers, feature gameplay |
| `data/` | Static typed content (MODULE 03+) | definitions, catalog, seed `.tres`, appearance/animation profiles | Runtime progress / GameState mutation |
| `docs/` | Документация репозитория | GDD, tech plan, module specs, decisions, perk effect contracts | Runtime code |
| `game/` | Canonical gameplay runtime | `state/` GameState; `day/` GameDay; `salary/` SalaryMine; `media/` Media; `dating_overload/` DatingOverload; `first_clone/` FirstClone; `clone_incremental/` CloneIncremental; `clone_visualization/` lab-local CloneVisualizationController; `progression/` Progression; `rivals/` RivalEncounters; `girls/` GirlDiscovery; `dating/` DatingCore; `relationships/` Relationships; `story/` Story | Parallel resource copies / EventBus / effect engines |
| `ui/` | Phone journal + dating UI shell | `phone/phone_journal.tscn` (status + story + girls + MEDIA + ПЕРЕГРУЗКА + КЛОНЫ counts/rates + salary); `dating/dating_ui.tscn` (result panel) | Final phone/date art |
| `world/` | World service + 9 location blockouts + tests | `World` autoload, locations (lab hosts MODULE 19 visual slots), markers, transitions, MODULE 12 test | Open-world streaming / MODULE 20 world expansion |
| `main.tscn` | Canonical entry | bootstrap → apartment via `World` | Бог-объект |
| `project.godot` | Godot project settings | app/input/display/layers/plugins/autoloads | Legacy `Game` singleton |
| `icon.svg` | Иконка приложения | — | — |

### `characters/`

- `framework/character_actor.tscn` + `character_actor.gd` — `CharacterActor` (CharacterBody3D presence)
- `framework/character_animation_controller.gd` — semantic AnimationPlayer presentation
- `framework/character_factory.gd` — static spawn helper (not autoload)
- `male/male_base_visual.tscn` — male glTF wrapper (`Superhero_Male_FullBody`)
- `female/female_base_visual.tscn` — female glTF wrapper (`Casual`)
- `player/` — FPS controller (invisible first-person; unchanged locomotion)
- `test/character_framework_test.tscn` — MODULE 04 self-test runner

### `core/`

- `df_log.gd` — `DfLog`
- `main_bootstrap.gd` — entry → `World.boot_from_main()` → apartment (FPS test harness kept at `world/test/player_fps_test.tscn`)
- `interactable.gd` — `Interactable` contract (`can_interact` / `get_interaction_prompt` / `interact`)

### `data/`

- `types/game_types.gd` — `class_name GameTypes` shared enums (incl. `CharacterBodyType`)
- `types/perk_ids.gd` — `class_name PerkIds` 32 canonical perk `StringName` constants
- `definitions/*.gd` — typed `Resource` schemas (incl. dating action/event/pool/greeting/farewell, discovery, appearance)
- `catalog/content_catalog.tres` — explicit production catalog (no FS scan); through MODULE 17: 12 girls / 11 rivals / 12 discovery situations
- `catalog/content_db.gd` — autoload `ContentDB` (load/index/validate/lookup; `try_get_girl`/`try_get_rival` for safe missing-content presentation)
- `content/` — production seed `.tres` (traits, perks, competitions, locations, stages, appearances, animations, girls, rivals, discovery, dating)
- `test/` — fixtures + MODULE 06–09 test content (`dating_test_fixtures.gd`, discovery/rival fixtures; not in production catalog)

### `game/state/`

- `game_state.gd` — autoload `GameState`: currency/XP/characteristics + `purchased_perks` + `defeated_rivals` + `lose_authority` + discovery/contacts/clues/trait reveal/reactions/retry days (MODULE 08) + relationship clamp `[-5,+5]` + date cooldown / played dating events / last date IDs / secondary reveal (MODULE 10)
- `game_state_self_test.gd` — reproducible MODULE 02 API/invariant tests

### `game/relationships/`

- `relationships.gd` — autoload `Relationships` (after DatingCore): apply `DatingResult` exactly once, completion XP via `add_experience(1)`, date cooldown day seam, event-history exclusions/cycle reset
- `relationship_date_result.gd` / `relationship_types.gd` — typed apply result + availability/error constants
- `test/relationships_test.tscn` + `relationships_self_test.gd` — MODULE 10 headless runner

### `game/story/`

- `story.gd` — autoload `Story` (after Relationships): stage completion rules, girl/rival gates, stage-derived `StoryFeature`, STAGE_6 world-expansion seam
- `story_ids.gd` / `story_types.gd` / `story_stage_progress.gd` — reserved IDs, enums, typed progress read model
- `test/story_test.tscn` + `story_self_test.gd` — MODULE 11 headless runner
- Stage catalog remains `data/definitions/story_stage_definition.gd` + `data/content/stages/stage_0..7.tres` (ContentDB)

### `game/girls/`

- `girl_discovery.gd` — autoload `GirlDiscovery`: discover, begin/select approach, cooldown day seam, Good Profile clue, Story reserved-girl gate (`STORY_WRONG_STAGE` / `STORY_RIVAL_REQUIRED`, not FAILURE), test content overrides
- `girl_discovery_attempt.gd` — transient attempt session
- `girl_actor.gd` / `girl_actor.tscn` — Interactable + CharacterActor + 4m seen trigger
- `test/girl_discovery_test.tscn` + `girl_discovery_self_test.gd` — MODULE 08 headless runner

### `game/dating/`

- `dating_core.gd` — autoload `DatingCore` (after GirlDiscovery): one active date session, planner, perks, money, known reactions; returns `DatingResult.date_delta` only
- `dating_session.gd` / typed request/result/decision/execution helpers
- `primary_trait_evaluator.gd` / `secondary_trait_evaluator.gd` / `dating_event_planner.gd` — pure helpers
- `test/dating_test.tscn` + `dating_self_test.gd` — MODULE 09 headless runner

### `ui/dating/`

- `dating_ui.tscn` + `dating_ui.gd` — functional MODAL_UI date choices (not final art)

### `game/progression/`

- `progression.gd` — autoload `Progression`: purchase, cost `3^N`, tree prereqs, availability, `perk_purchased`
- `test/progression_test.tscn` + `progression_self_test.gd` — MODULE 05 headless runner

### `game/day/`

- `game_day.gd` — autoload `GameDay`: integer day index + `advance_day()` + `day_advanced` (no clock/time-of-day)
- `day_advance_interactable.gd` — apartment Interactable → `GameDay.advance_day()`

### `game/salary/`

- `salary_mine.gd` — autoload `SalaryMine` (after World): periods, pending, manual/advance claim, passive inertia
- `salary_types.gd` / `salary_status.gd` / `salary_claim_result.gd` — claim enums + read models
- `salary_station.gd` — mine Interactable manual claim cycle
- `test/salary_mine_test.tscn` + `salary_mine_self_test.gd` — MODULE 13 headless runner

### `game/rivals/`

- `rival_encounters.gd` — autoload `RivalEncounters`: encounter lifecycle, competition gates, perk hooks, minigame contract
- `rival_competition_runner.gd` — autoload `RivalCompetitionRunner` (after RivalEncounters): SLAP/DANCE/SIGMA/MONEY routes; Hostile Acquisition signal; Player MINIGAME; exactly-once submit
- `rival_encounter_session.gd` / `rival_competition_request.gd` / `rival_competition_result.gd` / `rival_encounter_result.gd` — typed transient objects
- `rival_fake_competition_runner.gd` — test-only forced WIN/LOSS via `set_competition_runner` seam
- `rival_actor.gd` — thin Interactable adapter (`[E] Вызвать`)
- `test/rival_encounter_test.tscn` + `rival_encounter_self_test.gd` — MODULE 06 headless runner

### `minigames/slap/`

- `slap_match.gd` — headless Slap FSM + formulas + perk rules (MODULE 07A)
- `slap_timing.gd` — pure timing/grade helpers
- `slap_minigame.tscn` / `slap_minigame.gd` — CanvasLayer overlay UI over current 3D world
- `test/slap_minigame_test.tscn` + `slap_minigame_self_test.gd` — MODULE 07A headless runner (uses RivalCompetitionRunner)

### `minigames/dance/`

- `dance_match.gd` — headless Dance FSM (demo/repeat/own), generation, streak, Appearance perks
- `dance_timing.gd` — pure move evaluator + window/error/grade helpers
- `dance_minigame.tscn` / `dance_minigame.gd` — CanvasLayer overlay; WASD via `move_*` actions
- `test/dance_minigame_test.tscn` + `dance_minigame_self_test.gd` — MODULE 07B headless runner

### `minigames/sigma/`

- `sigma_match.gd` — headless Sigma composure FSM + Aura formulas + six perk rules (MODULE 07C)
- `sigma_minigame.tscn` / `sigma_minigame.gd` — CanvasLayer overlay; relative mouse X; Q/R specials
- `test/sigma_minigame_test.tscn` + `sigma_minigame_self_test.gd` — MODULE 07C headless runner

### `minigames/money/`

- `money_match.gd` — headless Money auction FSM + stake/ceiling formulas (MODULE 07D)
- `money_minigame.tscn` / `money_minigame.gd` — CanvasLayer overlay; spends `GameState.money` on won rounds; mouse UI
- `test/money_minigame_test.tscn` + `money_minigame_self_test.gd` — MODULE 07D headless runner

### `world/`

- `world.gd` — autoload `World` (after Story): access/travel/load/unload, persistent Player + PhoneJournal under `WorldHost`
- `world_types.gd` / `world_access_result.gd` — travel/access enums + typed access result
- `world_location.gd` — scene-root contract + local marker lookup / gate refresh
- `world_transition.gd` — E-only travel Interactable (never body_entered)
- `world_feature_gate.gd` — StoryFeature barrier (city public segment)
- `player_spawn_point.gd` / `npc_spawn_point.gd` / `story_event_point.gd` — Marker3D slots (NPC does not auto-spawn)
- `phone_interactable.gd` — apartment phone → `PhoneJournal.open`
- `locations/<id>/<id>.tscn` — nine blockout scenes (hub-and-spoke)
- `test/player_fps_test.tscn` — technical FPS testbed (preserved)
- `test/world_location_test.tscn` + `world_location_self_test.gd` — MODULE 12 headless runner
- `test/game_state_test.tscn` / `content_data_test.tscn` — MODULE 02/03 runners
- `test/fixtures/` — spawn-missing / duplicate-marker fixtures

## Physics layers (3D)

| Layer | Name | Use |
|---|---|---|
| 1 | `world` | Solid geometry |
| 2 | `player` | Player body |
| 3 | `interactable` | Interactable Area3D targets |
| 4 | `characters` | CharacterActor body collision |

Player: layer 2, mask world|characters (1|8).  
CharacterActor: layer characters (8), mask world (1).  
InteractionTarget Area3D on characters: layer interactable (4).  
Interaction ray mask: world + interactable (bits 1+3).

## Autoload

Dependency-safe production order (`project.godot`):

| Name | Почему |
|---|---|
| `GodotIQRuntime` | Editor/runtime bridge addon; не gameplay |
| `GameState` | Canonical runtime playthrough state (MODULE 02); owns purchased perks + salary fields |
| `ContentDB` | Read-only static content lookup/validation (MODULE 03); after GameState; no GameState dependency |
| `Progression` | Perk purchase / tree / cost API (MODULE 05); after ContentDB; uses GameState + ContentDB |
| `GameDay` | Explicit day-index broadcaster (MODULE 13); after Progression; no time-of-day |
| `RivalEncounters` | Rival encounter session/lifecycle (MODULE 06); after GameDay; uses GameState + ContentDB competitions; no EventBus |
| `RivalCompetitionRunner` | Production minigame launch/submit (MODULE 07D routes SLAP/DANCE/SIGMA/MONEY); Hostile Acquisition hook; after RivalEncounters; Callable seam only |
| `GirlDiscovery` | Girl discovery / acquaintance (MODULE 08); after ContentDB; uses GameState + ContentDB + Story gates; GameDay subscriber |
| `DatingCore` | One-date runtime (MODULE 09); after GirlDiscovery; uses GameState + ContentDB; does **not** apply relationship; assigns monotonic `date_id` |
| `Relationships` | Apply date results / completion / date cooldown / event history (MODULE 10); after DatingCore; GameDay subscriber |
| `Story` | Stage completion / StoryFeature / girl-rival gates (MODULE 11); after Relationships |
| `World` | Location load/travel/access (MODULE 12); after Story; StoryFeature gates; not GameState.unlock_location for the 9 |
| `SalaryMine` | Salary periods / pending / claim / passive (MODULE 13); after World; StoryFeature.SALARY_MINE gate |
| `Media` | Attention / photo session / publish / incoming offers / feed (MODULE 15); after SalaryMine; StoryFeature.MEDIA_ATTENTION gate |
| `DatingOverload` | Personal date capacity / demand backlog / feed boost / problem recognition (MODULE 16); after Media; activates from Media `overload_ready` at STAGE_4 |
| `FirstClone` | One-off first clone sequence (MODULE 17); after DatingOverload; eligibility → calibration → physical representative → WORK/DATING aggregate counts; lab representative suppressed when `CloneVisualizationController` owns lab |
| `CloneIncremental` | Late clone economy (MODULE 18); after FirstClone; owns production/work/dating formulas → `GameState.set_late_rates`; lab terminal assign/upgrades; Phone read-only rates; economy owner (MODULE 19 is visualization only) |

### `game/media/`

- `media.gd` — autoload `Media`: Attention API, photo session complete, 1 photo/day publish, threshold incoming offers, `overload_ready`
- `media_content.gd` — fixed shot/pose/threshold constants (not ContentDB)
- `media_types.gd` / `media_photo_session.gd` / `media_publish_result.gd` — typed helpers + session + publish result
- `photo_session_interactable.gd` — world interactable for the one-time Editor shoot
- `test/media_test.tscn` + `media_self_test.gd` — MODULE 15 headless runner

### `game/dating_overload/`

- `dating_overload.gd` — autoload `DatingOverload`: activation, daily body capacity, demand waves, backlog, feed boost, recognition handoff
- `dating_overload_types.gd` / `dating_demand_entry.gd` / `dating_overload_status.gd` — enums/constants, demand row, status snapshot
- `test/dating_overload_test.tscn` + `dating_overload_self_test.gd` — MODULE 16 headless runner

### `game/first_clone/`

- `first_clone.gd` — autoload `FirstClone`: eligibility, one-off calibration sequence, preview spawn, WORK/DATING assignment into `GameState` aggregate counts; `reconstruct_representative` suppressed when laboratory has `CloneVisualizationController` and `total_clones >= 1`
- `first_clone_types.gd` / `first_clone_status.gd` / `first_clone_actor.gd` / `first_clone_machine_interactable.gd` / `clone_calibration_minigame.gd` — types, status snapshot, physical representative (fallback when no viz controller), machine interactable, 3-pass minigame
- `test/first_clone_test.tscn` + `first_clone_self_test.gd` — MODULE 17 headless runner

### `game/clone_incremental/`

- `clone_incremental.gd` — autoload `CloneIncremental`: real-time free-clone production, rate recompute into `GameState.set_late_rates`, work/dating assignment, 3 Money upgrade lines (`cost = 30×3^level`), backlog-first auto dates then XP/UP; no individual clone entities; remains economy owner under MODULE 19
- `clone_incremental_types.gd` / `clone_incremental_status.gd` / `clone_upgrade_purchase_result.gd` — formulas (production 30→5 s, work 20→70 Money/min/clone, dating 0.50→1.75 dates/min/clone), status snapshot, purchase result
- `clone_terminal_interactable.gd` / `clone_terminal_ui.gd` — physical lab terminal (assign Work/Dating + buy upgrades); Phone stays read-only
- `test/clone_incremental_test.tscn` + `clone_incremental_self_test.gd` — MODULE 18 headless runner

### `game/clone_visualization/`

- `clone_visualization_controller.gd` — **lab-local** (not autoload): reads `GameState` aggregate counts + `CloneIncremental` signals; owns dating rooms / work / free / mass-flow presentation; never mutates economy
- `dating_room_visual.gd` / `clone_visual_actor.gd` / `clone_visualization_types.gd` — 10 date rooms, presentation-only `CharacterActor` wrappers, scene-cycle enums
- Caps: 10 date / 3 work / 2 free / 2 mass-flow (≤27 presentation actors); overflow → external labels + mass corridor (`ВНЕШНИЕ ПЛОЩАДКИ`)
- `test/clone_visualization_test.tscn` + `clone_visualization_self_test.gd` — MODULE 19 headless runner

## Canonical future destinations (ещё не созданы)

```text
audio/
```

`minigames/slap/` реализован (MODULE 07A).  
`minigames/dance/` реализован (MODULE 07B).  
`minigames/sigma/` реализован (MODULE 07C).  
`minigames/money/` реализован (MODULE 07D).  
`game/girls/` реализован (MODULE 08).  
`game/dating/` реализован (MODULE 09).  
`game/relationships/` реализован (MODULE 10).  
`game/story/` реализован (MODULE 11).  
`world/` каркас 9 локаций реализован (MODULE 12).  
`game/day/` + `game/salary/` реализова зарплаты (MODULE 13).  
`data/content/` production content through Scientist / first clone (MODULE 14A+14B+17); inventories `docs/content/MANUAL_CONTENT_14A.md`, `docs/content/MANUAL_CONTENT_14B.md`, `docs/content/MANUAL_CONTENT_17.md`.
`game/content/test/module_14a_vertical_test.tscn` — MODULE 14A headless integration runner.
`game/content/test/module_14b_vertical_test.tscn` — MODULE 14B Editor → STAGE_4 / MEDIA_ATTENTION headless runner.
`ui/phone/` функциональный журнал: status + story + girls + MEDIA + ПЕРЕГРУЗКА + КЛОНЫ (after total≥1, read-only counts + Money/min + Dates/min) + salary; STAGE_4: media → overload → Scientist hunt; STAGE_5: before clone lab handoff / after clone automation handoff without President (MODULE 08/10/12/13/14/15/16/17/18/19); финальный phone shell — MODULE 22.  
`ui/dating/` функциональный dating UI (MODULE 09/10 result panel).
`game/media/test/media_test.tscn` — MODULE 15 Media headless runner.
`game/dating_overload/test/dating_overload_test.tscn` — MODULE 16 Dating Overload headless runner.
`game/first_clone/test/first_clone_test.tscn` — MODULE 17 First Clone headless runner.
`game/clone_incremental/test/clone_incremental_test.tscn` — MODULE 18 Clone Incremental headless runner.
`game/clone_visualization/test/clone_visualization_test.tscn` — MODULE 19 Physical Clone Visualization headless runner.
Laboratory (`world/locations/laboratory/`): MODULE 19 local→mass visuals; STOP before MODULE 20 world expansion / President.

## Donor

Read-only: `../date_factory_legacy` (`legacy-v1`).  
Runtime не зависит от donor.
