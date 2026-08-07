# PROJECT STRUCTURE

Фактическая структура после **MODULE 08 — Girl Discovery & Phone Journal**.  
Godot 4.7 · Forward Plus · main scene: `res://main.tscn` → `world/test/player_fps_test.tscn`

## Top-level (существует сейчас)

| Path | Назначение | Можно | Нельзя |
|---|---|---|---|
| `addons/` | Editor/tool plugins | GodotIQ и будущие tooling plugins | Gameplay systems |
| `assets/` | Импортируемые визуальные ресурсы | модели, текстуры, материалы, fonts, props, animation libraries | Gameplay scripts / domain logic |
| `characters/` | Player + Character Framework | `framework/`, `male/`, `female/`, `player/`, `test/` | Dating/Rival/AI domain systems |
| `core/` | Техническая инфраструктура | debug helpers, bootstrap, Interactable contract | Game managers, feature gameplay |
| `data/` | Static typed content (MODULE 03+) | definitions, catalog, seed `.tres`, appearance/animation profiles | Runtime progress / GameState mutation |
| `docs/` | Документация репозитория | GDD, tech plan, module specs, decisions, perk effect contracts | Runtime code |
| `game/` | Canonical gameplay runtime | `state/` GameState; `progression/` Progression; `rivals/` RivalEncounters; `girls/` GirlDiscovery | Parallel resource copies / EventBus / effect engines |
| `ui/` | Phone journal + future HUD shell | `phone/phone_journal.tscn` (MODULE 08 functional journal) | Dating CTAs / messaging |
| `world/` | World / test scenes | FPS test, GameState/ContentDB self-tests | Central game controllers |
| `main.tscn` | Canonical entry | bootstrap в FPS test | Бог-объект |
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
- `main_bootstrap.gd` — entry → FPS test world (RivalCompetitionRunner is autoload; not attached here)
- `interactable.gd` — `Interactable` contract (`can_interact` / `get_interaction_prompt` / `interact`)

### `data/`

- `types/game_types.gd` — `class_name GameTypes` shared enums (incl. `CharacterBodyType`)
- `types/perk_ids.gd` — `class_name PerkIds` 32 canonical perk `StringName` constants
- `definitions/*.gd` — typed `Resource` schemas (incl. `AppearanceProfileDefinition`, `AnimationProfileDefinition`, `DiscoverySituationDefinition`, `DiscoveryApproachDefinition`)
- `catalog/content_catalog.tres` — explicit production catalog (no FS scan); `discovery_situations` empty until MODULE 14
- `catalog/content_db.gd` — autoload `ContentDB` (load/index/validate/lookup; discovery situation/approach indexes)
- `content/` — production seed `.tres` (traits, perks, competitions, locations, stages, appearances, animations)
- `test/` — fixtures + `content_data_self_test.gd` + MODULE 06 `rival_test_*.tres` + MODULE 08 `girl_test_discovery*`, `discovery_situation_test_*` (not in production catalog)

### `game/state/`

- `game_state.gd` — autoload `GameState`: currency/XP/characteristics + `purchased_perks` + `defeated_rivals` + `lose_authority` + discovery/contacts/clues/trait reveal/reactions/retry days (MODULE 08)
- `game_state_self_test.gd` — reproducible MODULE 02 API/invariant tests

### `game/girls/`

- `girl_discovery.gd` — autoload `GirlDiscovery`: discover, begin/select approach, cooldown day seam, Good Profile clue, test content overrides
- `girl_discovery_attempt.gd` — transient attempt session
- `girl_actor.gd` / `girl_actor.tscn` — Interactable + CharacterActor + 4m seen trigger
- `test/girl_discovery_test.tscn` + `girl_discovery_self_test.gd` — MODULE 08 headless runner

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

### `world/test/`

- `player_fps_test.tscn` — technical FPS testbed
- `test_interactables.gd` — smoke interactable wiring + modal test UI
- `game_state_test.tscn` — MODULE 02 self-test runner
- `content_data_test.tscn` — MODULE 03 self-test runner

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
`ui/phone/` функциональный журнал (MODULE 08); финальный phone shell — MODULE 22.

## Donor

Read-only: `../date_factory_legacy` (`legacy-v1`).  
Runtime не зависит от donor.
