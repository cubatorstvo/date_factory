# PROJECT STRUCTURE

Фактическая структура после **MODULE 27 — Full Game QA** (RC QA gate in progress; balance/content locked).  
Godot 4.7 · Forward Plus · main scene: `res://main.tscn` → title menu → World after New/Continue/Load

UI architecture: `docs/ui/UI_ARCHITECTURE.md`.  
Presentation (audio/camera/VFX): `docs/presentation/PRESENTATION_ARCHITECTURE.md`.  
Persistence: `docs/persistence/SAVE_ARCHITECTURE.md`.  
Balance report: `docs/balance/BALANCE_REPORT.md`.  
Full Game QA: `docs/qa/FULL_GAME_QA_REPORT.md`, `docs/qa/REGRESSION_MATRIX.md`, `docs/qa/KNOWN_ISSUES.md`.  
Licenses: `docs/ASSET_LICENSES.md`.

## Top-level (существует сейчас)

| Path | Назначение | Можно | Нельзя |
|---|---|---|---|
| `addons/` | Editor/tool plugins | GodotIQ и будущие tooling plugins | Gameplay systems |
| `assets/` | Импортируемые визуальные + audio ресурсы | модели, текстуры, материалы, fonts, props, animation libraries, `audio/` music/SFX/ambience + license texts | Gameplay scripts / domain logic |
| `audio/` | MODULE 23 AudioDirector + semantic IDs | `audio_director.gd` autoload; `audio_ids.gd`; `test/`; volumes applied by SaveSystem | Gameplay authority / own settings file |
| `characters/` | Player + Character Framework | `framework/` (+ semantic animation aliases); `male/`; `female/`; `player/` (+ `camera_feedback.gd`, pose export); `test/` | Dating/Rival/AI domain systems |
| `core/` | Техническая инфраструктура | debug helpers, bootstrap → title then World, Interactable contract | Game managers, feature gameplay |
| `data/` | Static typed content (MODULE 03+) | definitions, catalog, seed `.tres`, appearance/animation profiles | Runtime progress / GameState mutation |
| `docs/` | Документация репозитория | GDD, tech plan, module specs, decisions, `ui/`, `presentation/`, `persistence/SAVE_ARCHITECTURE.md`, `balance/BALANCE_REPORT.md`, `qa/` Full Game QA, `ASSET_LICENSES.md` | Runtime code |
| `game/` | Canonical gameplay runtime | `state/` GameState (+ save export/restore); `day/` GameDay; `salary/` SalaryMine; `media/` Media; `dating_overload/` DatingOverload; `first_clone/` FirstClone; `clone_incremental/` CloneIncremental (+ fractions runtime save); `clone_visualization/` lab-local CloneVisualizationController; `late_game/` LateGameExpansion (+ Global Terminal UI); `final_date/` scene-local FinalDateController + FinalDateUI; `progression/` Progression; `rivals/` RivalEncounters + exhibition seam; `girls/` GirlDiscovery; `dating/` DatingCore; `relationships/` Relationships; `story/` Story; `balance/test/` MODULE 26 test-only projection (no runtime BalanceManager); `qa/test/` MODULE 27 full_game_integration harness | Parallel resource copies / EventBus / effect engines |
| `qa/` | MODULE 27 test manifest | `test_manifest.json` required_for_rc suite list | Gameplay systems |
| `tools/qa/` | MODULE 27 one-command runner | `run_all_tests.py` (+ timeouts / nonzero fail exit) | Product content |
| `persistence/` | MODULE 24 SaveSystem | `save_system.gd` autoload; `save_types.gd`; `save_result.gd`; `save_slot_metadata.gd`; `test/` | Gameplay formulas / second save service |
| `presentation/` | Soft VFX / camera helpers (MODULE 23) | `vfx/` ScreenFlash, UiAccentPulse, MeshEmissivePulse, BeaconPulse, PresentationCamera | VFX framework / gameplay mutation |
| `ui/` | Presentation shell (MODULE 22–24) | Theme; GameHUD; Phone; Progression; Dating; RivalEncounterUI; format/scale/tutorial; `frontend/` Title/Pause/Settings; `AudioDirector` via `AudioIds` | UIManager / gameplay formulas |
| `minigames/` | Rival competition overlays | `slap/`, `dance/`, `sigma/`, `money/` + shell; semantic SFX + Slap→CameraFeedback | Domain encounter formulas (stay in RivalEncounters) |
| `world/` | World service + 9 location blockouts + tests | `World` autoload; locations; pose save/restore; title defer; PersistentUI hosts Phone + GameHUD | Open-world streaming / ambience autoload SM |
| `default_bus_layout.tres` | Five audio buses | Master / Music / SFX / UI / Ambience | Extra bus frameworks |
| `main.tscn` | Canonical entry | bootstrap → apartment via `World` | Бог-объект |
| `project.godot` | Godot project settings | app/input/display/layers/plugins/autoloads / bus layout | Legacy `Game` singleton |
| `icon.svg` | Иконка приложения | — | — |

### `characters/`

- `framework/character_actor.tscn` + `character_actor.gd` — `CharacterActor` (CharacterBody3D presence)
- `framework/character_animation_controller.gd` — semantic AnimationPlayer presentation (MODULE 23 aliases + fallback; never gates gameplay)
- `framework/character_factory.gd` — static spawn helper (not autoload)
- `male/male_base_visual.tscn` — male glTF wrapper (`Superhero_Male_FullBody`)
- `female/female_base_visual.tscn` — female glTF wrapper (`Casual`)
- `player/` — FPS controller (invisible first-person); `camera_feedback.gd` player-local impulses (not autoload)
- `test/character_framework_test.tscn` — MODULE 04 self-test runner

### `audio/` (MODULE 23)

- `audio_director.gd` — autoload `AudioDirector`: 4 music states, 1s A/B crossfade, SFX pool 8 + UI pool 4, volume seams 0..1, minigame duck −4 dB
- `audio_ids.gd` — `class_name AudioIds`: semantic IDs, path maps, `music_state_for_stage`
- `test/audio_director_self_test.gd` — buses / music / pools / duck smoke
- Assets live under `assets/audio/` (music / sfx / ambience / licenses) — see `docs/ASSET_LICENSES.md`

### `presentation/` (MODULE 23)

- `vfx/screen_flash.gd` — `ScreenFlash` canvas flashes (media / slap / clone reveal)
- `vfx/ui_accent_pulse.gd` — `UiAccentPulse` dating/badge pulses
- `vfx/mesh_emissive_pulse.gd` — `MeshEmissivePulse`
- `vfx/beacon_pulse.gd` — `BeaconPulse` final signal
- `vfx/presentation_camera.gd` — `PresentationCamera` FOV helpers → player `CameraFeedback`

### `core/`

- `df_log.gd` — `DfLog`
- `main_bootstrap.gd` — entry → `World.prepare_for_title()` → `TitleMenu` (New/Continue/Load then World travel; FPS test harness at `world/test/player_fps_test.tscn`)
- `interactable.gd` — `Interactable` contract (`can_interact` / `get_interaction_prompt` / `interact`)

### `persistence/` (MODULE 24)

- `save_system.gd` — autoload `SaveSystem` (before `AudioDirector`): 3 manual + autosave JSON, atomic+backup, settings.cfg, restore orchestration
- `save_types.gd` — `class_name SaveTypes`: `Slot`, `ErrorCode`, schema v1, paths, autosave debounce 0.75 s
- `save_result.gd` / `save_slot_metadata.gd` — typed I/O result + list-card metadata
- `test/save_system_self_test.tscn` — MODULE 24 headless runner
- Architecture: `docs/persistence/SAVE_ARCHITECTURE.md`

### `data/`

- `types/game_types.gd` — `class_name GameTypes` shared enums (incl. `CharacterBodyType`)
- `types/perk_ids.gd` — `class_name PerkIds` 32 canonical perk `StringName` constants
- `definitions/*.gd` — typed `Resource` schemas (incl. dating action/event/pool/greeting/farewell, discovery, appearance)
- `catalog/content_catalog.tres` — explicit production catalog (no FS scan); after MODULE 25: **23 girls / 19 rivals / 22 discovery situations** / **62** central dating events / **45** appearance profiles (see `docs/content/MANUAL_CONTENT_COMPLETE.md`)
- `catalog/content_db.gd` — autoload `ContentDB` (load/index/validate/lookup; `try_get_girl`/`try_get_rival` for safe missing-content presentation)
- `content/` — production seed `.tres` (traits, perks, competitions, locations, stages, appearances, animations, girls, rivals, discovery, dating)
- `test/` — fixtures + MODULE 06–09 test content (`dating_test_fixtures.gd`, discovery/rival fixtures; not in production catalog)

### `game/state/`

- `game_state.gd` — autoload `GameState`: currency/XP/characteristics + `purchased_perks` + `defeated_rivals` + `lose_authority` + discovery/contacts/clues/trait reveal/reactions/retry days (MODULE 08) + relationship clamp `[-5,+5]` + date cooldown / played dating events / last date IDs / secondary reveal (MODULE 10) + clone aggregates/late rates (MODULE 17–18) + `world_reach` + three global upgrade levels 0..3 (MODULE 20); MODULE 24 `export_save_state` / `restore_save_state` (+ `state_restored`)
- `game_state_self_test.gd` — reproducible MODULE 02 API/invariant tests
- `test/game_state_save_self_test.tscn` — MODULE 24 GameState serialize round-trip

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

### `ui/` (MODULE 22–24)

- `theme/date_factory_theme.tres` + `date_factory_theme_builder.gd` — shared Theme
- `theme/ui_scale_helper.gd` — `UiScaleHelper` presets 100/125/150% (persisted via SaveSystem `ui_scale`)
- `ui_number_format.gd` — `UiNumberFormat` grouped / K·M·B / money / signed / rate
- `hud/game_hud.tscn` + `game_hud.gd` — persistent `GameHUD`; Money/Auth/XP/UP; event-driven; hide strip on MODAL_UI/MINIGAME/PAUSED; notification rail + stage/feature toasts; grouped reward SFX only (no passive Money spam)
- `tutorial/tutorial_prompt.gd` — seven first-use prompts, HUD-owned (no autoload); seen ids in `user://settings.cfg`
- `frontend/title_menu.*` / `pause_menu.*` / `settings_panel.*` / `frontend_save_api.gd` — MODULE 24 title/pause/settings presentation over `SaveSystem`
- `phone/phone_journal.tscn` + `phone_journal.gd` — five tabs; UI click/back/denied/purchase + media SFX via `AudioDirector`
- `progression/progression_ui.tscn` + `progression_ui.gd` — full 32-perk modal; purchase/denied/click SFX
- `dating/dating_ui.tscn` + `dating_ui.gd` — themed date UI + relationship SFX / accent pulse
- `rivals/rival_encounter_ui.tscn` + `rival_encounter_ui.gd` — choose/result + rival win/loss SFX
- `hud/test/`, `progression/test/` — presentation self-tests
- Architecture: `docs/ui/UI_ARCHITECTURE.md`

### `game/progression/`

- `progression.gd` — autoload `Progression`: purchase, cost `3^N`, tree prereqs, availability, `perk_purchased`
- `progression_interactable.gd` — apartment entry → spawns Progression UI modal
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
- `rival_competition_runner.gd` — autoload `RivalCompetitionRunner` (after RivalEncounters): SLAP/DANCE/SIGMA/MONEY routes; Hostile Acquisition signal; Player MINIGAME; exactly-once submit; MODULE 21 `run_exhibition_competition` (Slap/Dance only, callback to FinalDateController, no Authority/defeat)
- `rival_encounter_session.gd` / `rival_competition_request.gd` / `rival_competition_result.gd` / `rival_encounter_result.gd` — typed transient objects
- `rival_fake_competition_runner.gd` — test-only forced WIN/LOSS via `set_competition_runner` seam
- `rival_actor.gd` — thin Interactable adapter (`[E] Вызвать`)
- `test/rival_encounter_test.tscn` + `rival_encounter_self_test.gd` — MODULE 06 headless runner

### `minigames/`

- `common/minigame_shell.gd` — `MinigameShell`: shared Theme apply, score/result presentation helpers (MODULE 22)
- `slap/` — Slap FSM + CanvasLayer overlay (MODULE 07A; Theme via shell)
- `dance/` — Dance FSM + overlay (MODULE 07B)
- `sigma/` — Sigma FSM + overlay (MODULE 07C)
- `money/` — Money auction FSM + overlay (MODULE 07D)
- Each family keeps `*_match.gd` formulas + `test/*_minigame_test.tscn` headless runners

### `world/`

- `world.gd` — autoload `World` (after Story): access/travel/load/unload; persistent Player + `PersistentUI` (`PhoneJournal` + `GameHUD`) under `WorldHost`; `get_game_hud()`; MODULE 24 `export_world_save_state` / `restore_saved_location` / `prepare_for_title`
- `world_types.gd` / `world_access_result.gd` — travel/access enums + typed access result
- `world_location.gd` — scene-root contract + marker lookup / gate refresh; attaches `LocalAmbiencePlayer` when location id allows
- `local_ambience_player.gd` — scene-local Ambience-bus loop (`factory_hum`); salary_mine / laboratory / production_area / final_location only; freed on travel
- `world_transition.gd` — E-only travel Interactable (never body_entered)
- `world_feature_gate.gd` — StoryFeature barrier (city public segment)
- `player_spawn_point.gd` / `npc_spawn_point.gd` / `story_event_point.gd` — Marker3D slots (NPC does not auto-spawn)
- `phone_interactable.gd` — apartment phone → `PhoneJournal.open`
- `locations/<id>/<id>.tscn` — nine blockout scenes (hub-and-spoke)
- `test/player_fps_test.tscn` — technical FPS testbed (preserved)
- `test/world_location_test.tscn` + `world_location_self_test.gd` — MODULE 12 headless runner
- `test/world_save_pose_self_test.gd` — MODULE 24 pose/location restore
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
| `CloneIncremental` | Late clone economy (MODULE 18); after FirstClone; owns production/work/dating formulas → `GameState.set_late_rates`; lab terminal assign/upgrades; Phone read-only rates; economy owner; queries LateGameExpansion global ×2^n seams |
| `LateGameExpansion` | Earth Reach + global upgrades (MODULE 20); after CloneIncremental; STAGE_6 Reach 0..100; multipliers for CloneIncremental; Production Area Global Terminal; Reach100 → `Story.complete_world_expansion()` → FINALE / `FINAL_DATE` |
| `SaveSystem` | Persistence (MODULE 24); after LateGameExpansion, **before** AudioDirector; schema v1 JSON slots + autosave; settings.cfg; restore orchestration |
| `AudioDirector` | Presentation audio (MODULE 23); after SaveSystem; music states / pools / volumes / duck; volumes applied from SaveSystem; **no** gameplay authority |

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

- `clone_incremental.gd` — autoload `CloneIncremental`: real-time free-clone production, rate recompute into `GameState.set_late_rates`, work/dating assignment, 3 Money upgrade lines (`cost = 30×3^level`), backlog-first auto dates then XP/UP; no individual clone entities; remains economy owner under MODULE 19; MODULE 24 `export_runtime_state` / `restore_runtime_state` (`production_elapsed_seconds`, `money_fraction`, `date_fraction`)
- `clone_incremental_types.gd` / `clone_incremental_status.gd` / `clone_upgrade_purchase_result.gd` — formulas (production 30→5 s, work 20→70 Money/min/clone, dating 0.50→1.75 dates/min/clone), status snapshot, purchase result
- `clone_terminal_interactable.gd` / `clone_terminal_ui.gd` — physical lab terminal modal (assign Work/Dating + buy upgrades; MODULE 22 Theme); Phone stays read-only
- `test/clone_incremental_test.tscn` + `clone_incremental_self_test.gd` — MODULE 18 headless runner

### `game/clone_visualization/`

- `clone_visualization_controller.gd` — **lab-local** (not autoload): reads `GameState` aggregate counts + `CloneIncremental` signals; owns dating rooms / work / free / mass-flow presentation; never mutates economy
- `dating_room_visual.gd` / `clone_visual_actor.gd` / `clone_visualization_types.gd` — 10 date rooms, presentation-only `CharacterActor` wrappers, scene-cycle enums
- Caps: 10 date / 3 work / 2 free / 2 mass-flow (≤27 presentation actors); overflow → external labels + mass corridor (`ВНЕШНИЕ ПЛОЩАДКИ`: Работа / Свидания / Ожидают)
- `test/clone_visualization_test.tscn` + `clone_visualization_self_test.gd` — MODULE 19 headless runner

### `game/late_game/`

- `late_game_expansion.gd` — autoload `LateGameExpansion`: STAGE_6 Earth Reach (`world_reach` 0..100), three global upgrade tracks (`GLOBAL_PRODUCTION` / `GLOBAL_WORK` / `GLOBAL_DATING`, levels 0..3 → ×1/×2/×4/×8, costs 1000/5000/25000), Reach from `late_experience_granted` (+2 each), Reach100 → `Story.complete_world_expansion()` + extraterrestrial signal; no country/logistics sim
- `late_game_types.gd` / `late_game_status.gd` / `global_upgrade_purchase_result.gd` — enums, status snapshot, typed purchase result
- `global_expansion_terminal_interactable.gd` / `global_expansion_terminal_ui.gd` — Production Area Global Terminal modal (Reach, rates, assign, global upgrades; MODULE 22 Theme)
- `global_expansion_event_interactable.gd` — three optional one-time FPS events (+10 Reach each)
- `world_reach_visual.gd` — presentation thresholds 0/25/50/75/100
- `test/late_game_test.tscn` + `late_game_self_test.gd` — MODULE 20 headless runner

### `game/final_date/`

- `final_date_controller.gd` — **scene-local** (not autoload) inside `final_location.tscn`: staged FINALE sequence (intro → events → DANCE exhibition → walk → SLAP exhibition → assessment); own connection score; no DatingCore
- `final_date_types.gd` / `final_date_ui.gd` — phases/failure reasons/event copy; themed CanvasLayer (choices, fail retry, success ending + `[Продолжить]`; MODULE 22 Theme/`UiNumberFormat`)
- `final_checkpoint_interactable.gd` / `final_signal_interactable.gd` — FPS checkpoints + answer-signal entry
- Content: `girl_final_target` («Последняя»), `rival_final_ceremonial` (DANCE), `rival_final_gravity` (SLAP) — exhibition-only
- Success once: relationship +5 / conquered / `add_experience(1)`; fail → full retry, zero permanent penalties
- `test/final_date_test.tscn` + `final_date_self_test.gd` — MODULE 21 headless runner

## Canonical status / next destinations

Persistence through MODULE 24 remains complete: SaveSystem (**schema v1** unchanged through MODULE 27; 3+autosave, atomic+backup, settings.cfg, title/pause).

After **MODULE 25 — Content Completion** (content locked):

- Production catalog: **23 girls** (16 ordinary 4×4 + 6 story + 1 final), **19 rivals** (12 ordinary + 5 Earth story + 2 final), **22** discovery situations.
- Dating: cafe common **24**, ordinary signatures **16**, greetings **8**, farewells **5**, central events **62**.
- World flavor **24** + scenic gags **12**; late `UpgradeLevelVisual` tiers presentation-only.
- Canonical inventory: `docs/content/MANUAL_CONTENT_COMPLETE.md` (prior slice notes 14A/14B/17 remain historical).

After **MODULE 26 — Balance / Anti-Grind** (balance locked):

- Only production rule change: Earth **story rival loss Authority −1 → 0** (ordinary loss −1 floor 0; exhibition 0). No other production constants retuned — clone / Stage6 / President / salary / perk / Media budgets passed.
- Clean Auth ladder locked: `0 → 2 → 4 → 7 → 10 → 15`.
- Test-only harness: `game/balance/test/`. Report: `docs/balance/BALANCE_REPORT.md`.
- Evidence: `tmp/m26_a_rival_encounter_test.log`, `tmp/m26_balance_self_test.log`.

After **MODULE 27 — Full Game QA** (RC QA; docs draft Wave G):

- Manifest + runner: `qa/test_manifest.json`, `tools/qa/run_all_tests.py`; evidence under `tmp/qa/`.
- Scripted full-game integration: `game/qa/test/full_game_integration_test.tscn` — Wave C **ALL PASS (157)** (Route A/B + save).
- QA docs: `docs/qa/FULL_GAME_QA_REPORT.md`, `REGRESSION_MATRIX.md`, `KNOWN_ISSUES.md` (BLOCKER/MAJOR open = 0 at draft; verdict **PENDING** Orchestrator).
- Static scans: `tmp/qa/scans/` (placeholders / donor / absolute paths / schema v1).
- Manual F5 routes A–F: **NOT EXECUTABLE IN ENVIRONMENT** in Wave G — do not invent completion.
- Known non-blocking: headless SIGSEGV after ALL PASS; `world_location` engine crash pending recheck disposition.
- No MODULE 28 features; schema remains **v1**.

Remaining:

- Orchestrator RC close (recheck pending suites; set READY / NOT READY).
- MODULE 28 — Release Integration (only after MODULE 27 PASS).

Gameplay headless runners remain under each `game/**/test/` and `minigames/**/test/`.  
Full-game integration: `game/qa/test/`.  
Balance runner: `game/balance/test/`.  
UI presentation runners: `ui/hud/test/`, `ui/progression/test/`.  
Audio runner: `audio/test/`.  
Save runner: `persistence/test/`.

## Donor

Read-only: `../date_factory_legacy` (`legacy-v1`).  
Runtime не зависит от donor.
