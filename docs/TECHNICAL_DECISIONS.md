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

---

## MODULE 03: typed Resources + explicit ContentCatalog

Context:
Нужен static content layer без механик исполнения и без JSON/CSV parser.

Options:
- JSON/CSV + custom loader
- Filesystem recursive scan of `res://data/content`
- Typed custom Resources + explicit catalog Resource

Decision:
Custom `Resource` definitions under `data/definitions/`, seed `.tres` under `data/content/`, one explicit `ContentCatalog` at `data/catalog/content_catalog.tres`. No production FS scan. Test fixtures stay under `data/test/` and are not registered in the production catalog.

Reason:
Editor-friendly typing, Git-friendly diffs, deterministic startup, clear production vs test boundary.

Scope:
`data/**`, `docs/PROJECT_STRUCTURE.md`

---

## MODULE 03: ContentDB autoload ownership

Context:
Consumers need a single read-only lookup/validation entry point.

Options:
- Pass ContentCatalog Resource manually everywhere
- Autoload `ContentDB`
- Per-folder mini-managers

Decision:
Autoload `ContentDB` → `res://data/catalog/content_db.gd`, registered after `GameState`. Loads catalog once, indexes by ID/enum, `validate_all()`, getters return null + `push_error` on missing. No `_process`, no scene changes, never mutates GameState.

Reason:
Matches MODULE 02 autoload pattern; ContentDB must boot without runtime state and GameState must reset without ContentDB.

Scope:
`data/catalog/content_db.gd`, `project.godot` `[autoload]`

---

## MODULE 03: shared enum ownership in GameTypes

Context:
Stage/characteristic enums must not be redefined per system.

Options:
- Keep enums inside GameState and duplicate in definitions
- Single `class_name GameTypes` shared enums
- Giant future `Enums.gd`

Decision:
`res://data/types/game_types.gd` owns `PlayerCharacteristic`, `GameStage` (0..7), `ActionTag` (12), primary/secondary traits, dating categories, competition types, perk sections. `GameState` consumes `GameTypes.*` and no longer declares its own Stage/Characteristic enums. Note: GDScript reserved word `trait` — definition fields use `primary_trait` / `secondary_trait`; competition identity field is `competition_type`.

Reason:
One canonical enum source; MODULE 02 numeric stage values preserved; MODULE 02 tests updated accordingly.

Scope:
`data/types/game_types.gd`, `game/state/game_state.gd`, `game/state/game_state_self_test.gd`

---

## MODULE 03: validation approach

Context:
Need pass/fail content validation for editor/headless without a heavy framework.

Options:
- Editor-only plugin validator
- Runtime assert-only
- `ContentDB.validate_catalog` / `validate_all` returning `{ok, errors}`

Decision:
Lightweight validation in ContentDB covering duplicate IDs, trait partition (12 liked tags), perk counts/sections, competition mapping, action max 2 tags, stages reserved-ID rules (story girl/rival IDs may be reserved without GirlDefinition/RivalDefinition existing). Self-test: `world/test/content_data_test.tscn`.

Reason:
Enough for MODULE 03 DoD; no DSL, no quest/dialogue/RNG engines.

Scope:
`data/catalog/content_db.gd`, `data/test/content_data_self_test.gd`, `world/test/content_data_test.tscn`

---

## MODULE 04: CharacterActor + AnimationPlayer aliases

Context:
Need a reusable humanoid presence layer (male/female) with semantic animation aliases, without dating/AI systems. Donor used a manual per-frame bone sampler (character_anim_controller.gd).

Options:
- Copy donor manual bone sampler
- AnimationTree blend graphs per body
- Standard AnimationPlayer + DF alias AnimationLibrary resources

Decision:
- CharacterActor (CharacterBody3D) owns collision, VisualRoot, anchors, and appearance application.
- CharacterAnimationController binds an AnimationPlayer and loads profile libraries under library names df / df_seated.
- Male base: Superhero_Male_FullBody.gltf via characters/male/male_base_visual.tscn; visual_scale 1.0 on VisualRoot (mesh is already ~1.8m after humanoid retarget).
- Female base: Casual.gltf via characters/female/female_base_visual.tscn; visual_scale 1.0.
- Physics layer 4 characters; player collision_mask = world|characters; InteractionTarget Area3D on interactable for ray hits.
- Static CharacterFactory.create helper (not autoload).
- Content profiles: appearance_male_base / appearance_female_base, animation_male_base / animation_female_base.

Reason:
Imported DF alias libraries play correctly through native AnimationPlayer; no need for donor sampler. Visual scale stays on VisualRoot so world/player scale remain meters.

Scope:
characters/framework/*, characters/male/, characters/female/, characters/test/, data/content/appearances/, data/content/animations/, data/catalog/content_catalog.tres, project.godot layer 4, characters/player/player.tscn mask only.

---

## MODULE 04: SkeletonProfileHumanoid BoneMap on import

Context:
Male/female donor meshes use non-humanoid bone names; DF alias libraries target Godot Humanoid names (Hips, Chest, ...).

Decision:
Copy DF_UAL_BoneMap.tres / DF_Women_BoneMap.tres and apply donor .gltf.import retarget settings (rename_bones, rest fixer) so imported skeletons expose Humanoid bone names. When CharacterActor attaches a new AnimationPlayer under the glTF root, root_node is .. so track paths like Armature/Skeleton3D:Hips resolve.

Reason:
Without BoneMap retarget, male stayed in T-pose (tracks could not bind). Female Casual already had compatible mapping after the same import treatment.

Scope:
assets/animation/universal_library/retargeted/DF_*_BoneMap.tres, male/female .gltf.import, character_actor.gd

---

## MODULE 05: Progression autoload

Context:
Need perk purchase, global cost, tree prerequisites, and characteristic growth without a generic effect engine.

Options:
- Stateless `ProgressionService` / RefCounted factory
- Autoload `Progression`
- Methods bolted onto GameState

Decision:
Autoload `Progression` → `res://game/progression/progression.gd`, registered **after** `ContentDB`. Persistent ownership stays in `GameState` (`_purchased_perks` Dictionary-as-set). `GameState.has_perk` is canonical; Progression aliases it. Purchase/cost/prereq/availability/tree reads live on Progression. Signal `perk_purchased(perk_id, characteristic, cost)`.

Reason:
Nearly stateless service with clear GameState + ContentDB composition; matches existing autoload pattern; no EventBus / `_process` / price cache / `chosen_branch`.

Scope:
`game/progression/progression.gd`, `project.godot` `[autoload]`, `game/state/game_state.gd`

---

## MODULE 05: characteristic lockdown + 3^N cost

Context:
Characteristic levels must equal owned perk count per characteristic; gameplay must not freely `set_characteristic`.

Decision:
- Replace public `set_characteristic` with `restore_characteristic` (save/debug only).
- Atomic `GameState._commit_perk_purchase` (spend points + add perk + char+1 or nothing) called only by Progression.
- Next purchase cost = integer `3^N` where `N = purchased_perks.size()` (multiply loop, not float `pow`).
- Tree prerequisites derived from `PerkDefinition.section` + `order_in_section` (branches never permanently lock each other; LATE requires BRANCH_A#2 OR BRANCH_B#2).
- ContentDB validates exact slots EARLY{1,2}, BRANCH_A{1,2}, BRANCH_B{1,2}, LATE{1,2} per characteristic.
- `PerkIds` constants for all 32 IDs; effect contracts documented only in `docs/PERK_EFFECT_CONTRACTS.md`.

Reason:
Enforces the MODULE 05 invariant, keeps GameState free of ContentDB at startup/reset, and avoids fake effect systems.

Scope:
`game/state/*`, `game/progression/**`, `data/types/perk_ids.gd`, `data/catalog/content_db.gd`, `docs/PERK_EFFECT_CONTRACTS.md`
