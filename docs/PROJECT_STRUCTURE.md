# PROJECT STRUCTURE

Фактическая структура после **MODULE 12 — World & Location Framework**.  
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
| `game/` | Canonical gameplay runtime | `state/` GameState; `progression/` Progression; `rivals/` RivalEncounters; `girls/` GirlDiscovery; `dating/` DatingCore; `relationships/` Relationships; `story/` Story | Parallel resource copies / EventBus / effect engines |
| `ui/` | Phone journal + dating UI shell | `phone/phone_journal.tscn` (rel/cooldown/completion); `dating/dating_ui.tscn` (result panel) | Final phone/date art |
| `world/` | World service + 9 location blockouts + tests | `World` autoload, locations, markers, transitions, MODULE 12 test | Open-world streaming / Salary Mine economy |
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
- `catalog/content_catalog.tres` — explicit production catalog (no FS scan); `discovery_situations` / dating greetings/farewells empty until MODULE 14
- `catalog/content_db.gd` — autoload `ContentDB` (load/index/validate/lookup; dating greeting/farewell + test overrides)
- `content/` — production seed `.tres` (traits, perks, competitions, locations, stages, appearances, animations)
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

| Name | Почему |
|---|---|
| `GodotIQRuntime` | Editor/runtime bridge addon; не gameplay |
| `GameState` | Canonical runtime playthrough state (MODULE 02); owns purchased perks |
| `ContentDB` | Read-only static content lookup/validation (MODULE 03); after GameState; no GameState dependency |
| `GirlDiscovery` | Girl discovery / acquaintance (MODULE 08); after ContentDB; uses GameState + ContentDB; no Dating |
| `DatingCore` | One-date runtime (MODULE 09); after GirlDiscovery; uses GameState + ContentDB; does **not** apply relationship; assigns monotonic `date_id` |
| `Relationships` | Apply date results / completion / date cooldown / event history (MODULE 10); after DatingCore |
| `Story` | Stage completion / StoryFeature / girl-rival gates (MODULE 11); after Relationships |
| `World` | Location load/travel/access (MODULE 12); after Story; StoryFeature gates; not GameState.unlock_location for the 9 |
| `Progression` | Perk purchase / tree / cost API (MODULE 05); after ContentDB; uses GameState + ContentDB |
| `RivalEncounters` | Rival encounter session/lifecycle (MODULE 06); after Progression; uses GameState + ContentDB competitions; no EventBus |
| `RivalCompetitionRunner` | Production minigame launch/submit (MODULE 07D routes SLAP/DANCE/SIGMA/MONEY); Hostile Acquisition hook; after RivalEncounters; Callable seam only |

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
`world/` каркас 9 локаций реализован (MODULE 12); Salary Mine economy — MODULE 13.  
`ui/phone/` функциональный журнал (MODULE 08/10/12 physical entry); финальный phone shell — MODULE 22.  
`ui/dating/` функциональный dating UI (MODULE 09/10 result panel).

## Donor

Read-only: `../date_factory_legacy` (`legacy-v1`).  
Runtime не зависит от donor.
