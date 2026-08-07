# PROJECT STRUCTURE

Фактическая структура после **MODULE 04 — Character Framework**.  
Godot 4.7 · Forward Plus · main scene: `res://main.tscn` → `world/test/player_fps_test.tscn`

## Top-level (существует сейчас)

| Path | Назначение | Можно | Нельзя |
|---|---|---|---|
| `addons/` | Editor/tool plugins | GodotIQ и будущие tooling plugins | Gameplay systems |
| `assets/` | Импортируемые визуальные ресурсы | модели, текстуры, материалы, fonts, props, animation libraries | Gameplay scripts / domain logic |
| `characters/` | Player + Character Framework | `framework/`, `male/`, `female/`, `player/`, `test/` | Dating/Rival/AI domain systems |
| `core/` | Техническая инфраструктура | debug helpers, bootstrap, Interactable contract | Game managers, feature gameplay |
| `data/` | Static typed content (MODULE 03+) | definitions, catalog, seed `.tres`, appearance/animation profiles | Runtime progress / GameState mutation |
| `docs/` | Документация репозитория | GDD, tech plan, module specs, decisions | Runtime code |
| `game/` | Canonical gameplay runtime | `state/` GameState | Parallel resource copies / EventBus |
| `ui/` | зарезервировано (HUD сейчас внутри Player) | общие UI позже | Domain logic |
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
- `main_bootstrap.gd` — entry → FPS test world
- `interactable.gd` — `Interactable` contract (`can_interact` / `get_interaction_prompt` / `interact`)

### `data/`

- `types/game_types.gd` — `class_name GameTypes` shared enums (incl. `CharacterBodyType`)
- `definitions/*.gd` — typed `Resource` schemas (incl. `AppearanceProfileDefinition`, `AnimationProfileDefinition`)
- `catalog/content_catalog.tres` — explicit production catalog (no FS scan)
- `catalog/content_db.gd` — autoload `ContentDB` (load/index/validate/lookup)
- `content/` — production seed `.tres` (traits, perks, competitions, locations, stages, appearances, animations)
- `test/` — fixtures + `content_data_self_test.gd` (not in production catalog)

### `game/state/`

- `game_state.gd` — autoload `GameState`: uses `GameTypes.GameStage` / `GameTypes.PlayerCharacteristic`
- `game_state_self_test.gd` — reproducible MODULE 02 API/invariant tests

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
| `GameState` | Canonical runtime playthrough state (MODULE 02) |
| `ContentDB` | Read-only static content lookup/validation (MODULE 03); after GameState; no GameState dependency |

## Canonical future destinations (ещё не созданы)

```text
audio/
minigames/
```

`ui/` существует как папка-заготовка; FPS HUD временно живёт в `player.tscn`.

## Donor

Read-only: `../date_factory_legacy` (`legacy-v1`).  
Runtime не зависит от donor.
