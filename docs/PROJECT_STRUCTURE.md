# PROJECT STRUCTURE

Фактическая структура после **MODULE 02 — Core Game State**.  
Godot 4.7 · Forward Plus · main scene: `res://main.tscn` → `world/test/player_fps_test.tscn`

## Top-level (существует сейчас)

| Path | Назначение | Можно | Нельзя |
|---|---|---|---|
| `addons/` | Editor/tool plugins | GodotIQ и будущие tooling plugins | Gameplay systems |
| `assets/` | Импортируемые визуальные ресурсы | модели, текстуры, материалы, fonts, props | Gameplay scripts / domain logic |
| `characters/` | Player / будущие character scenes | `player/` FPS controller | Dating/NPC domain systems |
| `core/` | Техническая инфраструктура | debug helpers, bootstrap, Interactable contract | Game managers, feature gameplay |
| `docs/` | Документация репозитория | GDD, tech plan, module specs, decisions | Runtime code |
| `game/` | Canonical gameplay runtime | `state/` GameState | Parallel resource copies / EventBus |
| `ui/` | зарезервировано (HUD сейчас внутри Player) | общие UI позже | Domain logic |
| `world/` | World / test scenes | test FPS world, state self-test, будущие локации | Central game controllers |
| `main.tscn` | Canonical entry | bootstrap в FPS test | Бог-объект |
| `project.godot` | Godot project settings | app/input/display/layers/plugins/autoloads | Legacy `Game` singleton |
| `icon.svg` | Иконка приложения | — | — |

### `characters/player/`

- `player.tscn` / `player.gd` — FPS locomotion, look, control modes, pause
- `player_interaction.gd` — center-screen RayCast interaction query

### `core/`

- `df_log.gd` — `DfLog`
- `main_bootstrap.gd` — entry → FPS test world
- `interactable.gd` — `Interactable` contract (`can_interact` / `get_interaction_prompt` / `interact`)

### `game/state/`

- `game_state.gd` — autoload `GameState`: stage, money, authority, experience, upgrade_points, characteristics, relationships, conquered girls, locations, story flags, clone counts, late rates
- `game_state_self_test.gd` — reproducible MODULE 02 API/invariant tests

### `world/test/`

- `player_fps_test.tscn` — technical FPS testbed (floor, door gap, steps, slope, jump platform, test interactables)
- `test_interactables.gd` — smoke interactable wiring + modal test UI
- `game_state_test.tscn` — headless/editor runner for GameState self-tests

## Physics layers (3D)

| Layer | Name | Use |
|---|---|---|
| 1 | `world` | Solid geometry |
| 2 | `player` | Player body |
| 3 | `interactable` | Interactable Area3D targets |

Player: layer 2, mask 1.  
Interaction ray mask: world + interactable (bits 1+3).

## Autoload

| Name | Почему |
|---|---|
| `GodotIQRuntime` | Editor/runtime bridge addon; не gameplay |
| `GameState` | Canonical runtime playthrough state (MODULE 02) |

## Canonical future destinations (ещё не созданы)

```text
audio/
data/
minigames/
```

`ui/` существует как папка-заготовка; FPS HUD временно живёт в `player.tscn`.

## Donor

Read-only: `../date_factory_legacy` (`legacy-v1`).  
Runtime не зависит от donor.
