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

---

## MODULE 06: RivalEncounters autoload + session

Context:
Rival challenges can start from world and future Dating/Story; session is transient; defeat/authority are persistent; MODULE 07 minigames must plug in without a generic EventBus.

Decision:
- Autoload `RivalEncounters` → `res://game/rivals/rival_encounters.gd`, registered **after** `Progression`.
- Transient `RivalEncounterSession` (RefCounted) owns phase/choice/snapshots for one encounter only.
- Typed `RivalCompetitionRequest` / `RivalCompetitionResult` / `RivalEncounterResult`; fake test runner forces WIN/LOSS × CLOSE/CRUSHING.
- Persistent state only in GameState: `defeated_rivals` set + `lose_authority(amount) -> int` (never `< 0`; never `add_authority(-1)`).
- Competition characteristic mapping via ContentDB `CompetitionDefinition` (SLAP→MUSCLE etc.).
- Presentation signals live on RivalEncounters (no EventBus). Test rivals load via ResourceLoader overrides — not production catalog.
- MODULE 07 gameplay plugs in via `set_competition_runner(Callable)` execution seam + typed result submit; `competition_requested` is notification/presentation only; fake runner remains test-only.

Reason:
Matches existing autoload ownership, keeps GameState free of ContentDB, and lets world/date hosts start encounters without a second global manager.

Scope:
`game/rivals/**`, `game/state/*`, `data/types/game_types.gd`, `data/test/rival_test_*.tres`, `project.godot` `[autoload]`

---

## MODULE 07A: Slap minigame + headless match

Context:
MODULE 06 begins competitions; production needs a real SLAP timing match that returns one `RivalCompetitionResult` without rewriting Authority/defeat.

Decision:
- Pure `SlapMatch` (RefCounted) owns FSM, formulas, streak, perks; injectable RNG; headless-testable.
- `SlapMinigame` CanvasLayer overlay ticks/input; world stays visible; player enters `ControlMode.MINIGAME`.
- Production launch originally used a slap-only host; MODULE 07B replaces it with unified `RivalCompetitionRunner` (see below).
- Input map: `minigame_primary` (Space+LMB), `minigame_special_1` (Q), `minigame_special_2` (R).
- Pause from MINIGAME restores prior mode; SceneTree pause stops pointer (`PROCESS_MODE_PAUSABLE`).
- No hidden hit RNG; difficulty only via width/speed from request level snapshot.

Reason:
Keeps RivalEncounters ownership of Authority/defeat, allows deterministic tests, and avoids a second global competition manager.

Scope:
`minigames/slap/**`, `characters/player/player.gd` (pause), `project.godot` `[input]`, perk contract docs

---

## MODULE 07B: RivalCompetitionRunner + Dance minigame

Context:
Slap-only host naming was ambiguous; Dance needs the same launch/submit lifetime as Slap across scene changes, without a plugin registry.

Decision:
- Autoload `RivalCompetitionRunner` → `res://game/rivals/rival_competition_runner.gd`, registered **after** `RivalEncounters`.
- `_ready()` → `RivalEncounters.set_competition_runner(run_competition)`; `competition_requested` is notify-only (no second launch path).
- Explicit `match competition_type`: SLAP → SlapMinigame, DANCE → DanceMinigame; SIGMA/MONEY originally unsupported (SIGMA added in MODULE 07C).
- Delete production `SlapCompetitionHost`; MODULE 06 `RivalFakeCompetitionRunner` uses `set_competition_runner` and restores production on teardown.
- `DanceMatch` headless FSM (OPPONENT_DEMO / PRE_ROLL / PLAYER_REPEAT / OWN_PREVIEW / PLAYER_OWN / ROUND_FEEDBACK); `DanceTiming.evaluate_move`; WASD via existing `move_*` actions (no `dance_*` InputMap).
- Appearance perks only: `APPEARANCE_STAGED_WALK`, `APPEARANCE_RHYTHM_IN_BODY`; no Authority mutation inside Dance.

Reason:
One runner for all four rival contests, one submit boundary, scene-independent lifetime, MODULE 06 tests stay independent.

Scope:
`game/rivals/rival_competition_runner.gd`, `game/rivals/rival_fake_competition_runner.gd`, `minigames/dance/**`, `minigames/slap/test/**`, `core/main_bootstrap.gd`, `project.godot` `[autoload]`, docs

## MODULE 07C: Sigma Pressure minigame

Context:
Third rival contest needs continuous mouse-X composure hold under baseline pressure and telegraphed disturbances, routed through the same `RivalCompetitionRunner` without Authority mutation inside the minigame.

Decision:
- Path `res://minigames/sigma/`: `SigmaMatch` (headless) + `SigmaMinigame` (CanvasLayer UI/input); contract `setup(request, …)` + `signal match_finished(result)`.
- Runner routes `SIGMA` → `SigmaMinigame`; `MONEY` remains explicit unsupported (debug error, no fake result). No `*CompetitionHost`.
- Snapshot Aura difference from `RivalCompetitionRequest` only; perk snapshot at match start via `PerkIds` (mid-match purchase ignored).
- Exact formulas: `half_width = clamp(0.30+diff*0.015, 0.20, 0.40)`, `pressure = clamp(0.32-diff*0.020, 0.18, 0.48)`; section 5.0s / hold 3.0s; target 3/5; mouse `0.0025`/px; error −0.65 once per excursion; perfect = win + 0 errors + perfect_time≥1.80.
- Six perks only: Pocket Mirror (Q 2.5s), Control Profile, Don't Blink First, Silence Longer (R 2.0s schedule freeze), Reverse Pressure, Atmospheric Influence.
- Mouse captured; FPS look disabled by existing `ControlMode.MINIGAME`; grade via `SlapTiming.compute_victory_grade`; `debug_score_summary` like `SIGMA 3:1`.

Reason:
Sigma is a continuous hold fantasy distinct from Slap/Dance timing, while sharing Runner lifetime, typed result, and score-grade matrix.

Scope:
`minigames/sigma/**`, `game/rivals/rival_competition_runner.gd`, `minigames/dance/test/dance_minigame_self_test.gd` (MONEY unsupported assert), docs

## MODULE 07D: Money Contest minigame

Context:
Fourth rival contest is a demonstration auction: bid levels vs rival Capital ceiling, real `GameState.money` spend only on won rounds, routed through the same `RivalCompetitionRunner`.

Decision:
- Path `res://minigames/money/`: `MoneyMatch` (headless) + `MoneyMinigame` (CanvasLayer UI); contract `setup(request, …)` + `signal match_finished(result)`.
- Runner routes `MONEY` → `MoneyMinigame` with `Input.MOUSE_MODE_VISIBLE`; all four types implemented. No `*CompetitionHost`.
- `stake_unit = max(1, floor(starting_money / (target_score * 15)))`; `rival_max_level = clamp(2 + floor(rival_capital/2) + var{-1,0,+1}, 2, 7)`; target 3/5; RAISE+1 / OUTBID+2@Capital≥3 / BUYOUT+3@Capital≥6.
- Intermediate bids cost 0; final winning purchase spends once via `GameState.spend_money`; Dignity Refund does not apply; Payable Intent has no extra match modifier.
- Hostile Acquisition: Runner emits `hostile_acquisition_requested(rival_id)` once on MONEY `PLAYER_WIN` if perk owned and `competition_modifier_id == &"money_acquisition"`; no world mutation in 07D.
- Grade via `SlapTiming.compute_victory_grade`; summary like `MONEY 3:1 spent=24`.

Reason:
Money is a spend-risk auction fantasy distinct from timing games, while sharing Runner lifetime, typed result, and score-grade matrix.

Scope:
`minigames/money/**`, `game/rivals/rival_competition_runner.gd`, `data/test/rival_test_money*.tres`, dance/sigma test MONEY-unsupported cleanup, docs

## MODULE 08: GirlDiscovery autoload + Phone Journal

Context:
Need fixed-situation girl discovery, authored acquaintance approaches, Experience gate, 1–3 day retry cooldown, and a functional phone journal — without Dating Core.

Decision:
- Autoload `GirlDiscovery` → `res://game/girls/girl_discovery.gd`, registered **after ContentDB** (before RivalEncounters is fine).
- Persistent discovery state in `GameState`: ordered unique `discovered_girls`, contacts, known clue indices, primary trait reveal, known reactions, retry days remaining.
- Static `DiscoverySituationDefinition` / `DiscoveryApproachDefinition` (`SUCCESS`/`FAILURE` only) indexed by ContentDB; production `discovery_situations` and `girls` stay empty until MODULE 14.
- Injectable RNG for failure cooldown `randi_range(1, 3)`; day seam `notify_game_day_advanced()` (no full clock).
- `APPEARANCE_GOOD_PROFILE`: on first discovery only, also reveal clue 1 if present (not retroactive).
- `GirlActor` thin Interactable + CharacterActor + 4m seen Area3D; hidden during cooldown.
- `PhoneJournal` MODAL_UI journal; discovered-only list; no Dating CTA; no permanent phone InputMap.
- Discovery resolve never calls `add_experience` / `mark_girl_conquered` / `add_girl_relationship`.

Reason:
Event-driven autoload matches MODULE 05/06 ownership; GameState keeps cooldown across scenes; ContentDB stays the static catalog owner.

Scope:
`data/definitions/discovery_*.gd`, `data/catalog/*`, `game/state/game_state.gd`, `game/girls/**`, `ui/phone/**`, `data/test/girl_test_*`, `data/test/discovery_*`, `project.godot` `[autoload]`, docs

## MODULE 09: DatingCore autoload — date_delta only

Context:
Need a full one-date runtime (arrival → greeting → 3 central events → farewell → secondary) with exact primary/secondary rules and dating perks, without applying relationship / XP / conquer / cooldown.

Decision:
- Autoload `DatingCore` → `res://game/dating/dating_core.gd`, registered **after GirlDiscovery**.
- Transient `DatingSession` (not saved); typed `DatingStartRequest` / `DatingResult` / `DatingDecisionRecord`.
- Category planner: 24 ordered triples (exclude CCC/SSS/GGG), content-aware filter, then slot-by-slot unique events; central IDs immutable after start.
- Primary evaluator reads ContentDB liked/disliked tags; greeting diagnostic only (`date_delta += 0`).
- Secondary after exactly 4 decision records; `date_delta = primary_total + secondary ∈ [-5,+5]`.
- External resolver seam: injectable Callable or `submit_action_execution_result` in `RESOLVING_ACTION`.
- Money: spend before resolve; Representation Expenses (first normal paid free); Dignity Refund on FAILURE; **no** `CAPITAL_NO_LIMIT` once/date freebie.
- Perks: silence/clues, Second Outfit flag, Public Significance, Encore tag transform, authored `required_perk_id` gates.
- Never call `set/add_girl_relationship`, `mark_girl_conquered`, `add_experience`. MODULE 10 applies `date_delta`.
- Functional `ui/dating/dating_ui.tscn` uses `PlayerController.ControlMode.MODAL_UI`.

Reason:
Keeps Dating Core as a pure session calculator so Relationships can own persistent consequences without mid-date save or dual managers.

Scope:
`game/dating/**`, `ui/dating/**`, `data/definitions/dating_*`, ContentDB greeting/farewell indexes + overrides, `ui/phone/phone_journal.gd` labels, `data/test/dating_test_fixtures.gd`, `project.godot`, docs

## MODULE 10: Relationships autoload — apply DatingResult + completion

Context:
MODULE 09 returns `DatingResult.date_delta` but must not mutate persistent girl relationship / XP / conquered. Need clamp `[-5,+5]`, repeat cooldown, central-event history cycle, first-+5 reward, Phone display.

Decision:
- Autoload `Relationships` → `res://game/relationships/relationships.gd`, registered **after DatingCore**.
- `_ready` connects `DatingCore.date_finished` → `apply_date_result` (guard `is_connected`) and optional `GameState.state_reset`.
- `GameState.set/add_girl_relationship` clamp to `[-5,+5]`.
- `DatingResult.date_id` (monotonic int from DatingCore) + transient `applied_date_ids` for exactly-once.
- Date cooldown `_girl_date_cooldown_days_remaining` separate from discovery retry; after each apply `rng.randi_range(1,3)`.
- `Relationships.notify_game_day_advanced()` decrements date cooldowns only; emit `girl_date_available_again` on 1→0 once. No TimeManager.
- Event history: ordered unique central IDs + last date's 3; `begin_new_event_cycle` on planner INSUFFICIENT (clear history, exclude last 3).
- First `relationship == +5` and not conquered → `mark_girl_conquered` then `add_experience(1)` (atomic UP). No auto primary/secondary reveal.
- Phone: signed relationship, completion label, date availability, secondary `?`/revealed. No invite CTA.
- `set_auto_apply_enabled(false)` seam for MODULE 09 purity tests.

Reason:
Keeps DatingCore a pure session scorer; Relationships owns persistent consequences and MODULE 11 `girl_completed` hook without Story/Time systems.

Scope:
`game/relationships/**`, GameState MODULE 10 fields/APIs, DatingResult/DatingCore date_id, PhoneJournal, dating_ui result panel, MODULE 02/09 test seams, `project.godot`, docs

---

## MODULE 11: Story / Stage Framework (no quest engine)

Alternatives considered:
- Generic QuestDefinition / Requirement DSL / Objective Graph
- Lightweight linear `Story` service over existing `GameState.stage` + ContentDB stage catalog

Decision:
- Autoload `Story` → `res://game/story/story.gd`, registered **after Relationships**.
- Persistent stage remains `GameState`; Story only calls `advance_stage(next)` (never `restore_stage` for gameplay).
- Exact 8 `StoryStageDefinition` resources with `requires_story_rival`, `completion_mode`, `next_stage`.
- Features (`StoryFeature`) derived from `stage >= threshold` — no feature bools in GameState.
- Only new story flag: `StoryIds.FLAG_WORLD_EXPANSION_COMPLETE` for STAGE_6 external milestone.
- GirlDiscovery consults Story girl gate after contact/cooldown, before Experience; reasons are not FAILURE.
- RivalEncounters core stays Story-free (MODULE 06 test rivals).
- Semantic unlocks only — no `unlock_location` / physical world (MODULE 12).

Reason:
Date Factory has a fixed linear stage map; a quest engine would overbuild without matching GDD.

Scope:
`game/story/**`, `StoryStageDefinition` + stage `.tres`, ContentDB stage validation, GirlDiscovery gate insert, `project.godot`, docs

---

## MODULE 12: World autoload — hub-and-spoke locations

Alternatives considered:
- Open-world streaming / seamless city
- Separate WorldManager + LocationManager + TravelManager
- Duplicate canonical access into `GameState.unlocked_locations`

Decision:
- Autoload `World` → `res://world/world.gd`, registered **after Story**.
- Nine compact scenes at `res://world/locations/<id>/<id>.tscn`; root `WorldLocation`.
- Hub-and-spoke: apartment ↔ city_hub ↔ seven spokes; travel only via `WorldTransition` (E / Interactable), never `body_entered`.
- Access map is an explicit StoryFeature table inside World; apartment always available; fail-closed if Story missing on gated IDs.
- `GameState.unlock_location` remains for future non-canonical/manual unlocks only — not used for the nine Story gates.
- `PUBLIC_CITY_ACCESS` is a `WorldFeatureGate` inside `city_hub` (second segment placeholder), not a 10th location.
- Persistent `WorldHost` under `/root`: `LocationRoot` + Player + PersistentUI (PhoneJournal); location scenes unload safely.
- Travel order: validate → load target → resolve spawn → MODAL_UI → swap → place (velocity/pitch reset) → free old → GAMEPLAY; busy = no queue; failed = no mutation.
- Physical apartment phone → existing `PhoneJournal.open`; no phone hotkey.
- Main bootstrap → `World.boot_from_main()` apartment; FPS test harness preserved.

Reason:
Matches compact GDD world, keeps Story as single access source, avoids manager proliferation and destructive unload races.

Scope:
`world/**`, `core/main_bootstrap.gd`, location `.tres` `scene_path`, ContentDB path validation, `project.godot`, docs

---

## MODULE 13: GameDay is day-index broadcaster only

Context:
MODULE 08/10 already use 1–3 day cooldowns; MODULE 13 adds salary period = one game day. Multiple independent day notifiers risk double-decrement bugs.

Decision:
`GameDay` is explicit day-index broadcaster only.
No time-of-day.
Production day progression occurs only via `GameDay.advance_day()`.
GirlDiscovery/Relationships/SalaryMine subscribe.

Reason:
One production `advance_day()` keeps cooldown and salary period seams aligned without a full Time System.

Scope:
`game/day/game_day.gd`, `game/salary/**`, GirlDiscovery/Relationships GameDay subscribe, `ui/phone/phone_journal.gd` salary section, `project.godot` `[autoload]`

## MODULE 14A: date_pool_* IDs + Phone Story progress API

Context:
MODULE 14A content spec drafts pool IDs as `dating_pool_*`, while ContentDB validation already requires `date_pool_*`. PhoneStory text must not invent a second progress API.

Decision:
1. Production pool resource IDs use `date_pool_*` (map from spec `dating_pool_*`).
2. PhoneJournal Story section reads `Story.get_current_progress()` (`StoryStageProgress`), not a non-existent `get_current_stage_progress`.
3. PhoneJournal adds top status (day/money/authority/experience/upgrade points) without redesigning the phone shell.

Reason:
Keep catalog validation and runtime APIs stable; 14A is content/integration, not a new framework.

Scope:
`data/content/dating/pools/**`, girl `dating_pool_ids`, `ui/phone/phone_journal.gd`, `docs/content/MANUAL_CONTENT_14A.md`, `game/content/test/module_14a_vertical_*`

## MODULE 14B: try_get_* + STAGE_4 media handoff (no Scientist content)

Context:
STAGE_4 catalog still points at reserved `girl_scientist` / `rival_scientist`, but MODULE 14B must not ship Scientist production content. Editor +5 unlocks `MEDIA_ATTENTION` and must leave Phone/World playable.

Decision:
1. `ContentDB.try_get_girl` / `try_get_rival` return null for missing reserved IDs (no hard fail).
2. PhoneJournal STAGE_4 story section shows media handoff (`Медийность` / `Фотосессия у Редактора`) when Scientist actors are absent.
3. Photo marker `story_point_editor_photo_session` may exist in `appearance_space` but does not launch media runtime.
4. Editor rival allows MONEY+DANCE; without Payable Intent MONEY stays locked and DANCE remains the no-grind path.

Reason:
Complete manual story through Editor without implementing MODULE 15 media systems or Scientist content.

Scope:
`data/catalog/content_db.gd` (try_get_*), `ui/phone/phone_journal.gd`, `data/content/**` Editor/ordinary packs, `docs/content/MANUAL_CONTENT_14B.md`, `game/content/test/module_14b_vertical_*`

## MODULE 15: Attention meter + Phone MEDIA section

Context:
After Editor / `MEDIA_ATTENTION`, the game needs a simple fame loop without a social-network simulator or calendar/capacity (MODULE 16).

Decision:
1. `Attention` is a persistent media meter `0..100`, non-spendable, no decay; owned by GameState, mutated via Media autoload.
2. Photo session creates exactly 3 fixed photo records; one photo may be published per GameDay (article does not consume the daily slot).
3. Incoming offers use 4 authored Attention thresholds (15/30/45/60) for deterministic first initiatives; at Attention ≥ 45 and ≥ 3 offers Media emits `overload_ready` once. MODULE15 offers are unscheduled; MODULE16 owns capacity/overlap.
4. PhoneJournal MEDIA section is additive (status/story/girls/salary preserved). Feed display is newest-first while persistent `media_feed_event_ids` remains chronological oldest→newest.
5. STAGE_4 Phone story handoff progresses: photo session → publish/incoming text → overload-ready demand text (no Scientist objective yet).

Reason:
Deliver player-visible fame growth and Phone tools while keeping a clean stop before Dating Overload.

Scope:
`game/media/**`, GameState media fields, `ui/phone/phone_journal.gd`, `docs/PROJECT_STRUCTURE.md`, GDD implementation notes

## MODULE 16: Dating Overload (body capacity + Phone backlog)

Context:
After Media `overload_ready`, the game must prove one body is not enough without building a calendar manager or Scientist/Lab/clone sequence (MODULE 17).

Decision:
1. After Media overload-ready at STAGE_4, personal hero capacity = 1 completed manual date per GameDay; demand generates 3 initial overlapping requests (authored 19:00/19:00/20:00 labels), then 2/day.
2. Backlog is non-punitive and persists; slots are presentation labels, not a real clock. The system is intentionally not a calendar manager.
3. Optional Feed Boost (`Поднять волну`) once/day: +5 Attention and next-day boosted demand wave; hidden after problem recognition.
4. Problem recognition after >=2 days, >=7 generated, >=4 backlog, >=1 completed personal date → mechanical flag immediately; Phone realization modal/toast deferred to next Phone open or safe GAMEPLAY with exact text «Проблема не в графике / Проблема в количестве меня».
5. PhoneJournal adds ПЕРЕГРУЗКА after MEDIA (incoming preserved); STAGE_4 story handoff switches to overload / recognition copy. Stage stays STAGE_4.

Reason:
Stage the clone premise as a felt capacity shortage without calendar optimization or MODULE 17 content.

Scope:
`game/dating_overload/**`, GameState overload fields, Relationships/DateVenue capacity gates, `ui/phone/phone_journal.gd`, docs structure/GDD notes

## MODULE 17: First Clone Sequence (Scientist → Lab → one-off clone)

Context:
After overload recognition, the player needs a causal Scientist route into Laboratory and a single physical first clone without starting MODULE 18 production/rates.

Decision:
1. Scientist + rival appear only after `DatingOverload.is_problem_recognized()` (StageActorAnchor `requires_overload_recognized`); XP4 / rival Authority7; Story owns STAGE_4→STAGE_5 and `StoryFeature.LABORATORY` (no manual `advance_stage`).
2. FirstClone is a one-off calibrated scene (3 deterministic SPACE passes); abort leaves clone counts at 0; assignment commits exactly WORK `1/1/0` or DATING `1/0/1` into `GameState.set_clone_counts`.
3. Aggregate clone counts on GameState are the source of truth; no individual persistent clone object / defects / QA / memories; money/min and dates/min stay 0 until MODULE 18.
4. Phone STAGE_4 after recognition shows Scientist hunt («Найти Учёную у закрытой лаборатории»); STAGE_5 before clone shows lab handoff without President; КЛОНЫ section appears only when `total_clones >= 1` (total/working/dating/free, no rates).
5. STOP before MODULE 18: no second clone, no passive ticking, no mass terminal, no President content.

Reason:
Prove the first physical double as the capacity solution while keeping Story, GameState aggregates, and Phone presentation coherent.

Scope:
`game/first_clone/**`, Scientist content, StageActorAnchor flag, lab/city markers, `ui/phone/phone_journal.gd`, docs §70

## MODULE 18: Clone Incremental Core (late rates + lab terminal)

Context:
After the first clone exists, the player needs automatic free-clone production, aggregate Work/Dating assignment, live Money/min and Dates/min, backlog-first auto dates, and three Money upgrade lines — without MODULE 19 physical slots or President content.

Decision:
1. `CloneIncremental` (autoload after FirstClone) is the canonical owner of late-rate computation; it writes only through `GameState.set_late_rates` / `set_clone_counts`. No individual clone records.
2. Exact MODULE 18 balance: production interval 30→5 s; work 20→70 Money/min/clone; dating 0.50→1.75 dates/min/clone; upgrade cost `30×3^level` (levels 0..5). Tunable later in MODULE 26.
3. Automated dates do not invoke DatingCore; overload backlog is fulfilled first; after backlog is empty each whole auto date grants `GameState.add_experience(1)` (+ UP seam as implemented). Rates use real gameplay seconds; GameDay does not simulate incremental output; no offline gains.
4. Management stays physical at the lab Clone Terminal (assign Work/Dating + buy upgrades). Phone КЛОНЫ is read-only: Всего / Свободно / Работают / Денег/мин / На свиданиях / Свиданий/мин; listens to `clone_counts_changed` and `late_rates_changed`.
5. STAGE_5 after first clone: «Автоматизация запущена. / Наращивай производство клонов.» Story never advances from clone numbers; no President / Stage 6. Physical crowd visualization is MODULE 19 (read-only over these aggregates).

Reason:
Turn the first clone into a small incremental factory while keeping GameState aggregates, DatingOverload backlog, and Phone presentation coherent — and STOP before physical crowd visualization.

Scope:
`game/clone_incremental/**`, GameState late rates / upgrade levels, DatingOverload backlog consume, lab terminal UI, `ui/phone/phone_journal.gd`, docs §82

## MODULE 19: Physical Clone Visualization (lab-local, aggregate projection)

Context:
After MODULE 18 rates exist, the player must see the local→mass transition in the laboratory FPS space without turning aggregate counts into individual NPC simulation, and without MODULE 20 world expansion / President.

Decision:
1. `CloneVisualizationController` is **lab-local** inside `laboratory.tscn` — not an autoload, not a global manager. No new GameState fields; no ContentDB expansion.
2. Visualization only over `GameState` aggregates (`total_clones` / `clones_working` / `clones_dating` / `free_clones`) plus `CloneIncremental` signals (`clone_produced`, counts). `CloneIncremental` still owns economy / rates / assignment.
3. Exact local caps: 10 date rooms / 3 work visuals / 2 free wait visuals / 2 mass-flow actors (≤27 presentation `CharacterActor`s). Overflow = external numeric labels + mass corridor (`ВНЕШНИЕ ПЛОЩАДКИ`); node count does not scale with aggregate totals.
4. Date-room scenes (CALM / OVER_EXPLAINING / SILENT_SUCCESS / MUTUAL_CONFUSION) and work/mass Tweens are ambient theater only — never call DatingCore, Money, Experience, or clone-count mutation.
5. When the lab controller is present and `total_clones >= 1`, FirstClone’s persistent representative is suppressed (no duplicate body). FirstClone reveal (`total_clones == 0`) and no-controller test fallback remain intact.
6. STOP: Stage stays STAGE_5; no President; no MODULE 20 countries / airports / global map.

Reason:
Prove the comedy of “same man, room after room” and the readable handoff from countable bodies to abstract mass flow, while keeping MODULE 18 aggregates as the only production truth.

Scope:
`game/clone_visualization/**`, narrow FirstClone representative suppress, `world/locations/laboratory/laboratory.tscn`, docs §39 / locations lab notes

## MODULE 20: LateGameExpansion (Reach + global ×2^n; STOP before final date)

Context:
After first clone + MODULE 18/19, STAGE_5 needs President as last Earth story girl, then STAGE_6 world expansion without a country/logistics simulator or MODULE 21 final date.

Decision:
1. President (`girl_president` STATUS+VARIETY_SEEKING, XP10; `rival_president` Auth10 / +5, MONEY/SIGMA/DANCE) appears at city_hub `ToProduction` only when `total_clones >= 1` (`StageActorAnchor.requires_first_clone_created` + GirlDiscovery `STORY_PREREQUISITE`). Existing Story owns STAGE_5→STAGE_6 / `WORLD_EXPANSION`.
2. Autoload `LateGameExpansion` (after CloneIncremental) owns `world_reach` 0..100 and three global tracks (`GLOBAL_PRODUCTION` / `GLOBAL_WORK` / `GLOBAL_DATING`, levels 0..3 → ×1/×2/×4/×8, costs 1000/5000/25000 Money). Reach starts at 0 on STAGE_6 — not derived from historical Experience.
3. Reach advances only from `CloneIncremental.late_experience_granted` (+2 per amount) while STAGE_6; backlog/manual dates give no Reach. Optional three Production Area FPS events (+10 once each) are not required.
4. `CloneIncremental` remains economy owner; it queries LateGameExpansion multipliers (absent/inactive → ×1). Effective production interval = `max(0.5, local / global_prod)`; work/dating rates multiply local formulas. Purchase emits refresh; production elapsed is preserved.
5. Production Area hosts Global Expansion Terminal (Reach, rates, assign, global upgrades) + Reach visuals 0/25/50/75/100. MODULE19 external label shows Работа / Свидания / Ожидают.
6. Reach ≥ 100 → exactly `Story.complete_world_expansion()` → FINALE + `FINAL_DATE` + extraterrestrial signal presentation. No `girl_final_target`, no final date gameplay, no country DB / logistics. STOP before MODULE 21.

Reason:
Earth story + fast planetary incremental peak without a second stage machine, without skipping Stage6 via old XP, and without shipping the alien finale early.

Scope:
`game/late_game/**`, GameState Reach/global levels, CloneIncremental multiplier seam, President content, Production Area terminal/events, Story world-expansion completion, Phone STAGE_5/6/FINALE copy, docs

## MODULE 21: FinalDateController staged sequence (STOP before polish)

Context:
After Reach100 / FINALE / `FINAL_DATE`, the game needs one concrete extraterrestrial date with «Последняя», two familiar minigames, full retry on fail, and a single success ending — without DatingCore, without alternate endings, and without MODULE 22 art/credits polish.

Decision:
1. Scene-local `FinalDateController` inside `final_location.tscn` (not an autoload). Authored phases: INTRO → EVENT_1 → RIVAL_1_DANCE → EVENT_2 → MOVE_TO_FINAL_TABLE → RIVAL_2_SLAP → EVENT_3/4 → assessment. Own transient connection score + characteristic variety; no DatingCore planner.
2. Production catalog **14 girls / 14 rivals**: add `girl_final_target` (display «Последняя», empty normal dating pool) + exhibition-only `rival_final_ceremonial` (DANCE) and `rival_final_gravity` (SLAP).
3. Narrow `RivalCompetitionRunner.run_exhibition_competition(request, rival_definition, result_callback)`: same Slap/Dance + control modes; callback to FinalDateController; **no** RivalEncounters submit / Authority / `mark_rival_defeated` / Heroic Defeat. Normal rival path unchanged.
4. Success once: `girl_final_target` relationship → +5, conquered → true, `GameState.add_experience(1)` (+UP). Canonical completion = `GameState.is_girl_conquered(girl_final_target)` (no `FLAG_FINAL_COMPLETE`). Functional ending screen + `[Продолжить]` returns to playable world.
5. Fail (rival loss or connection): comedy UI → **full** sequence retry; zero permanent penalties (money/authority/XP/relationship/reach/clones untouched). Infinite attempts.
6. STOP before MODULE 22: no final art, voice, prestige/NG+, alternate endings, alien world systems.

Reason:
Close the F5→ending main path with one deterministic staged finale while reusing existing minigames and the girl-conquest XP invariant.

Scope:
`game/final_date/**`, `RivalCompetitionRunner` exhibition seam, final content `.tres` + catalog 14/14, `world/locations/final_location/`, docs §43–44 / locations finale notes

## MODULE 22: UI / UX Integration (presentation only; STOP before MODULE 23)

Context:
Gameplay through Final Date is complete, but player-facing UI was still a functional prototype scatter: no permanent HUD, Phone was a long scroll, Progression was thin, Theme/number format/scale/tutorials were inconsistent, and modal ownership needed a clear presentation rule without a UI framework.

Decision:
1. One shared Theme `ui/theme/date_factory_theme.tres` (+ builder). No UIManager / ScreenManager / reactive store.
2. Exactly one persistent `GameHUD` under `WorldHost/PersistentUI` beside `PhoneJournal` (`World._ensure_game_hud` / `get_game_hud`). Shows only Money / Authority / Experience / Upgrade Points; event-driven; gameplay strip hidden on `MODAL_UI` / `MINIGAME` / `PAUSED`.
3. Notification rail + stage/feature toasts on GameHUD (queue max 3, ~2.2 s; no passive clone Money spam). Seven `TutorialPrompt` ids are runtime-only inside HUD — not GameState, not an autoload.
4. `UiNumberFormat` (K/M/B + money/signed/rate) and `UiScaleHelper` presets 100/125/150% — runtime-only; MODULE 24 may persist scale/tutorials.
5. PhoneJournal five tabs STATUS/STORY/GIRLS/MEDIA/CLONES; MEDIA gated by `StoryFeature.MEDIA_ATTENTION`; CLONES by `total_clones >= 1`; salary under STATUS; overload under MEDIA. Action APIs unchanged.
6. Full Progression UI (`ui/progression/progression_ui.*`) for all 32 perks via existing `Progression` purchase API; apartment Interactable open seam only.
7. DatingUI / RivalEncounterUI / `MinigameShell` / Clone+Global terminal UIs / FinalDateUI adopt Theme + readable presentation; gameplay controllers remain source of truth. Modal ownership = at most one owner via `PlayerController.ControlMode`.
8. STOP before MODULE 23: no audio/animation/VFX polish ahead.

Reason:
Unify presentation and readability for the full F5→ending route without inventing a UI framework or mutating balance/Story/economy.

Scope:
`ui/**` (Theme, HUD, Phone tabs, Progression, Dating, RivalEncounterUI, format/scale/tutorial helpers), `minigames/common/minigame_shell.gd` + minigame presentation glue, terminal/FinalDateUI Theme apply under `game/**`, narrow `world.gd` HUD attach, docs (`PROJECT_STRUCTURE`, this file, GDD §47, `docs/ui/UI_ARCHITECTURE.md`)

## MODULE 23: Audio / Animation / Feedback (presentation only; STOP before MODULE 24)

Context:
Gameplay and MODULE 22 UI are complete through Final Date, but the route lacked a shared sound language, music beds by stage, restrained camera impulses, semantic NPC reactions, and soft VFX — without inventing gameplay systems or a settings/save layer.

Decision:
1. Exact five buses in `default_bus_layout.tres`: Master 0 / Music −8 / SFX −3 / UI −5 / Ambience −10 dB. One compact autoload `AudioDirector` (after `LateGameExpansion`): MusicA/B 1s crossfade, SFX pool 8 + UI pool 4, volume seams 0..1, minigame duck −4 dB / restore 0.4 s.
2. Exactly four music states `MANUAL` / `MEDIA` / `CLONE` / `FINAL` via `AudioIds.music_state_for_stage`: PROLOGUE–STAGE_3→MANUAL, STAGE_4→MEDIA, STAGE_5–6→CLONE, FINALE→FINAL. Same-state travel does not restart. Semantic `AudioIds` → `play_ui`/`play_sfx` only (no raw paths in callers).
3. Ambience is **scene-local** `LocalAmbiencePlayer` on Ambience bus (`factory_hum` for salary_mine / laboratory / production_area / final_location); no ambience autoload SM; apartment/cafe/city skipped when no asset.
4. Player-local `CameraFeedback` (not autoload): caps rotation ≤2°, shake ≤0.025 m, FOV ≤3°, duration ≤0.20 s; `feedback_scale` 0..1 (scale 0 zeroes motion). Slap + First Clone / Final signal FOV helpers; Dance/Sigma/Money get no camera motion.
5. Preserve `CharacterAnimationController`; add semantic aliases (`react_*` / `victory` / `defeat` / `gesture_short`) with ordered clip fallbacks; never gate gameplay or `[Далее]`.
6. Soft VFX as static helpers under `presentation/vfx/` (`ScreenFlash`, `UiAccentPulse`, `MeshEmissivePulse`, `BeaconPulse`, `PresentationCamera`) — no framework; no blood; no per-clone audio/VFX storm.
7. Presentation never owns gameplay commits (XP / Authority / Story / Money / clones). No voice/TTS.
8. Licenses recorded in `docs/ASSET_LICENSES.md` (Kenney + Abstraction CC0; `final_sparse.wav` project-generated CC0). Architecture: `docs/presentation/PRESENTATION_ARCHITECTURE.md`.
9. STOP before MODULE 24: no settings menu, no persistence of volumes / camera scale / tutorials / UI scale.

Reason:
Give the finished route a coherent presentation layer with bounded pools and hard caps, while keeping gameplay controllers as source of truth and leaving settings/save for MODULE 24.

Scope:
`audio/**`, `assets/audio/**`, `default_bus_layout.tres`, `characters/player/camera_feedback.gd`, `characters/framework/character_animation_controller.gd` (aliases), `world/local_ambience_player.gd` + location attach, `presentation/vfx/**`, thin call-site seams in UI/minigames/game controllers, docs (`PROJECT_STRUCTURE`, this file, `UI_ARCHITECTURE` audio seams, `ASSET_LICENSES`, `PRESENTATION_ARCHITECTURE`)
