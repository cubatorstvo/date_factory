# TECHNICAL DECISIONS

Краткий decision log Date Factory v2.  
Записывать только существенные infrastructure/решения.

---

## GodotIQ addon retained

Context:
Нужен AI/editor bridge для разработки в Cursor.

Options:
- Не ставить addon и работать только filesystem tools
- Сохранить GodotIQ как editor/runtime bridge addon

Decision:
Оставить `addons/godotiq` (v0.5.16) и autoload `GodotIQRuntime`.

Reason:
Прямо ускоряет разработку; не содержит gameplay. Autoload — часть addon lifecycle, не gameplay manager.

Scope:
`addons/godotiq/`, `project.godot` `[autoload]` / `[editor_plugins]`

---

## No gameplay autoloads in MODULE 00

Context:
Нужно решить, создавать ли заранее Game/EventBus/SceneManager.

Options:
- Заранее создать несколько «стандартных» managers
- Начать без gameplay autoload

Decision:
Ни одного gameplay autoload. Только GodotIQRuntime.

Reason:
MODULE 00 — foundation. Game State и сервисы появятся по отдельным спецификациям (MODULE 02+).

Scope:
`project.godot`

---

## Debug via `DfLog` class, not autoload

Context:
Нужен минимальный debug baseline с меткой модуля.

Options:
- Autoload logger
- `class_name DfLog` static helpers
- Только стандартный `print`/`push_error`

Decision:
`core/df_log.gd` с `class_name DfLog` и static `info`/`warn`/`error`.

Reason:
Достаточно для MODULE 00, без глобального mutable state и без premature service.

Scope:
`core/df_log.gd`

---

## Temporary bootstrap on `main.tscn`

Context:
Нужен smoke-test запуска без gameplay.

Options:
- Пустая сцена без script
- Минимальный bootstrap + label

Decision:
`main.tscn` (Control) + `core/main_bootstrap.gd` + StatusLabel.

Reason:
Подтверждает запуск и debug path; легко удалить/заменить в MODULE 01.

Scope:
`main.tscn`, `core/main_bootstrap.gd`

---

## Canonical folders without empty placeholders

Context:
Спека задаёт canonical destinations (`audio/`, `characters/`, …).

Options:
- Создать все пустые папки сразу
- Создавать по мере появления реальных файлов

Decision:
Созданы только реально нужные сейчас: `addons/`, `assets/`, `core/`, `docs/`. Остальные — documented future destinations.

Reason:
Спека явно запрещает пустые каталоги «ради дерева».

Scope:
`docs/PROJECT_STRUCTURE.md`, filesystem

---

## Input Map baseline for MODULE 01

Context:
Нужен минимальный input set до Player FPS.

Options:
- Не трогать Input Map до MODULE 01
- Зафиксировать canonical actions сейчас

Decision:
Добавлены `move_forward/backward/left/right`, `jump`, `interact`, `pause` с desktop defaults WASD/Space/E/Esc.

Reason:
Требование MODULE 00; дальше не добавлять gameplay-specific actions заранее.

Scope:
`project.godot` `[input]`

---

## MODULE 01: rewrite FPS instead of porting donor player

Context:
Donor `scenes/player/player.gd` contains usable movement/look/ray ideas but is coupled to `Game`, phone, dating, upgrades, EventBus, sprint/bob.

Options:
- Copy donor player and strip dependencies
- Write a clean MODULE 01 controller from the new spec

Decision:
Write new `characters/player/*` + `core/interactable.gd`. Reuse numbers/ideas only (capsule ~1.8, eye ~1.65, step-up approach). No donor file copies.

Reason:
Spec forbids sprint/bob/domain coupling; clean rewrite is smaller than untangling legacy.

Scope:
`characters/player/`, `core/interactable.gd`, `world/test/`

---

## Control modes as player enum (not a framework)

Context:
Need GAMEPLAY / MODAL_UI / MINIGAME / PAUSED ownership.

Options:
- Separate InputGate autoload/service
- Enum + API on PlayerController

Decision:
`PlayerController.ControlMode` with `enter_gameplay/modal_ui/minigame/paused`.

Reason:
Minimal, local, enough for future consumers without a global state machine framework.

Scope:
`characters/player/player.gd`

---

## Physics layers: world / player / interactable

Context:
Need solids vs player vs interaction targets without future layer sprawl.

Options:
- Everything on layer 1
- Three named layers

Decision:
Layer1 `world`, Layer2 `player`, Layer3 `interactable`.

Reason:
Ray can hit interactables and be blocked by world; player collides only with world.

Scope:
`project.godot` layer names; player/test scenes

---

## MODULE 02: GameState as small dedicated autoload

Context:
Нужен один canonical runtime Game State, доступный всем будущим gameplay-модулям без поиска Node по SceneTree.

Options:
- Autoload `GameState`
- Scene-owned singleton node
- Resource + holder service
- Legacy-style `Game` facade

Decision:
Один маленький autoload `GameState` → `res://game/state/game_state.gd`. Без `class_name` (имя = autoload). Без EventBus, SaveManager, UI ownership, ticker/`_process`, salary/perk formulas, content DB.

Reason:
Для текущего маленького Godot-проекта autoload — самый прямой ownership; спека это явно допускает. Donor `Game` не переносится: он смешивал state, systems и UI coupling.

Scope:
`game/state/game_state.gd`, `project.godot` `[autoload]`, tests under `world/test/game_state_test.tscn`

---

## MODULE 02: experience → upgrade_points atomic grant

Context:
Продуктовое правило: опыт даёт баллы прокачки один-в-один, но баллы можно тратить независимо.

Options:
- Отдельные `add_experience` / `add_upgrade_points`
- Только atomic `add_experience(N)` → `+N` к обоим; spend только через `spend_upgrade_points`

Decision:
Gameplay grant path только `add_experience`. Публичного `add_upgrade_points` нет. `restore_upgrade_points` — только future save path. Authority не имеет spend API.

Reason:
Защищает инвариант «опытность и баллы не расходятся при наградах», не превращая state в perk system.

Scope:
`game/state/game_state.gd`

---

## MODULE 02: strict stage advance + restore path

Context:
Стадии сюжетно монотонны в gameplay, но save/load позже должен уметь восстановить произвольное значение.

Options:
- Свободный `set_stage`
- Только `advance_stage(+1)`
- `advance_stage` + отдельный `restore_stage`

Decision:
Gameplay: `advance_stage(next)` только если `next == current + 1`. Save/restore: `restore_stage`.

Reason:
Закрывает skip/regress в обычном API без блокировки будущего save.

Scope:
`game/state/game_state.gd`

---

## MODULE 01 pre-flight feel fixes (with MODULE 02)

Context:
Перед Game State спека требует починить air control и step-up safety.

Options:
- Отложить
- Исправить в том же milestone commit

Decision:
`air_acceleration = 8.0` (воздух ускоряет только при input, без air braking). Step-up применяет подъём только после `test_move` на полный collider.

Reason:
Закрывает MODULE 01 debt до появления state consumers.

Scope:
`characters/player/player.gd`
