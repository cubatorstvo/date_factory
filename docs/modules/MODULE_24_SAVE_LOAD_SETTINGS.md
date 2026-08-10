# MODULE 24 — SAVE / LOAD / SETTINGS

**Проект:** Date Factory  
**Модуль:** 24 — Save / Load / Settings  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** полноценное versioned сохранение всего production-state Date Factory v2, восстановление мира и late-game simulation, пользовательские настройки, title/pause front-end и безопасные autosave/manual save flows.  
**Предыдущий модуль:** MODULE 23 — Audio / Animation / Feedback  
**Следующий модуль:** MODULE 25 — Content Completion  
**Tech truth:** `docs/tech/TECH_PLAN_FULL.md`, MODULE 24

---

# 0. КРИТИЧЕСКАЯ ГРАНИЦА

MODULE 24 реализует:

```text
new v2 save schema
3 manual save slots
1 autosave
Continue / New Game / Load Game
manual Save / Load from pause
autosave on stable milestones
full GameState serialization
GameDay restore
CloneIncremental fractional-progress restore
world/location/player transform restore
settings persistence
settings UI
tutorial-seen persistence
```

MODULE 24 НЕ реализует:

- legacy-v1 save migration;
- Steam Cloud;
- achievements;
- encrypted saves;
- multiple profiles;
- account system;
- checkpoint rewind;
- save scumming prevention;
- offline clone production;
- mid-minigame saves;
- mid-date saves;
- mid-final-date saves;
- replay system.

Legacy save compatibility is explicitly NOT required by TECH_PLAN.

---

# 1. ARCHITECTURE — ONE PERSISTENCE AUTOLOAD

Create:

```text
SaveSystem
```

autoload.

Responsibilities:

```text
game save slots
autosave
schema encode/decode
save validation
load orchestration
settings ConfigFile
runtime settings application
save metadata
```

Do NOT create parallel:

```text
SaveManager
LoadManager
SettingsManager
ProfileManager
PersistenceBus
```

One service is enough.

---

# 2. AUTOLOAD ORDER

Current tail:

```text
LateGameExpansion
AudioDirector
```

Change to:

```text
LateGameExpansion
SaveSystem
AudioDirector
```

Reason:

`SaveSystem._ready()` loads settings before presentation systems fully start.

`AudioDirector` may query current SaveSystem settings during `_ready()`.

Gameplay systems remain independent of SaveSystem.

---

# 3. FILE PATHS

Use:

```text
user://saves/
```

Exact game-save files:

```text
user://saves/slot_1.json
user://saves/slot_2.json
user://saves/slot_3.json
user://saves/autosave.json
```

Temporary atomic-write files:

```text
*.tmp
```

Settings:

```text
user://settings.cfg
```

No save files inside `res://`.

---

# 4. SAVE SCHEMA VERSION

Exact initial:

```text
SAVE_SCHEMA_VERSION = 1
```

Every game save root contains:

```json
{
  "schema_version": 1,
  "saved_at_unix": 0,
  "game": {},
  "world": {},
  "runtime": {}
}
```

Optional metadata:

```text
build_label
```

may be added, but schema version is authoritative.

---

# 5. NO LEGACY MIGRATION

If:

```text
schema_version != 1
```

load rejects with:

```text
UNSUPPORTED_SCHEMA
```

Do NOT guess/migrate v1 donor/legacy formats.

Future schema migration may be added when v2 schema actually changes.

---

# 6. JSON, NOT RESOURCE SERIALIZATION

Game saves use:

```text
FileAccess
JSON.stringify()
JSON.parse_string()
```

Save payload must contain only JSON-safe types:

```text
bool
int/float
String
Array
Dictionary
null
```

Do NOT serialize:

```text
Resource
Node
StringName Variant directly without conversion
Transform3D Variant directly
DatingDemandEntry Resource
```

Encode them explicitly.

---

# 7. ATOMIC WRITE

Save flow:

```text
build payload
→ JSON.stringify
→ write slot.tmp
→ close
→ replace target atomically/best-effort
```

Never truncate the valid target before a complete temp write succeeds.

If temp write fails:

```text
old valid save remains
```

---

# 8. BACKUP

For each manual slot and autosave:

before replacing existing valid file:

```text
slot_1.json → slot_1.bak.json
```

Exact backup paths:

```text
slot_1.bak.json
slot_2.bak.json
slot_3.bak.json
autosave.bak.json
```

Keep only one backup per slot.

---

# 9. CORRUPTION RECOVERY

When loading target:

1. validate target;
2. if invalid/corrupt, try `.bak.json`;
3. if backup valid:
   - load backup;
   - return metadata flag `recovered_from_backup=true`;
4. otherwise fail visibly.

Do NOT silently start New Game after corrupt save.

---

# 10. SAVE SLOT TYPES

Exactly:

```text
MANUAL_1
MANUAL_2
MANUAL_3
AUTOSAVE
```

No quicksave slot in MODULE24.

---

# 11. SAVE METADATA

`get_slot_metadata(slot)` must work WITHOUT loading gameplay state.

Metadata derived from payload:

```text
exists
valid
schema_version
saved_at_unix
stage
game_day
location_id
money
authority
experience
total_clones
world_reach
final_completed
recovered_from_backup
```

UI summary example:

```text
СЛОТ 1
Стадия 5 · Лаборатория
День 9
Покоренных сердец 12
Клоны 34
08.08.2026 18:42
```

No screenshot thumbnail required.

---

# 12. CURRENT GAMESTATE REALITY

`GameState` already owns all persistent domain state for:

```text
stage
Money
Authority
Experience
Upgrade Points
4 characteristics
relationships
conquered girls
discovered girls
contacts
girl clues
revealed traits
known reactions
retry days
date cooldowns
played event history
last date event history
unlocked locations
story flags
clone counts
late rates
clone upgrades
world reach
global upgrades
perks
defeated rivals
salary
Media
DatingOverload
```

MODULE24 must serialize all of it.

Do NOT save only “important” fields.

---

# 13. GAMESTATE SAVE BLOCK — EXACT KEYS

Root:

```text
game.game_state
```

Exact logical keys:

```text
stage

money
authority
experience
upgrade_points

muscle
appearance
capital
aura

purchased_perks
defeated_rivals

girl_relationships
conquered_girls
discovered_girls
girl_contacts
known_girl_clues
revealed_primary_traits
known_girl_reactions
girl_retry_days_remaining
girl_date_cooldown_days_remaining
girl_played_dating_event_ids
girl_last_date_event_ids
revealed_secondary_traits

unlocked_locations
story_flags

salary

media

dating_overload

clones

late_game
```

Grouping may be nested as below.

---

# 14. BASE PROGRESSION PAYLOAD

```json
{
  "stage": 0,
  "money": 0,
  "authority": 0,
  "experience": 0,
  "upgrade_points": 0,
  "characteristics": {
    "muscle": 0,
    "appearance": 0,
    "capital": 0,
    "aura": 0
  },
  "purchased_perks": [],
  "defeated_rivals": []
}
```

StringName IDs serialize as normal Strings.

---

# 15. GIRL STATE PAYLOAD

```json
{
  "girls": {
    "relationships": {
      "girl_neighbor": 5
    },
    "conquered": [],
    "discovered": [],
    "contacts": [],
    "known_clues": {},
    "revealed_primary_traits": [],
    "known_reactions": {},
    "retry_days_remaining": {},
    "date_cooldown_days_remaining": {},
    "played_dating_event_ids": {},
    "last_date_event_ids": {},
    "revealed_secondary_traits": []
  }
}
```

Choose arrays for set-like values.

Do not serialize Dictionary keys as `StringName`.

Convert keys to String.

---

# 16. KNOWN CLUES

Encode:

```text
girl_id → [clue indices]
```

Example:

```json
"known_clues": {
  "girl_scientist": [0, 2]
}
```

Preserve exact revealed clue set.

---

# 17. KNOWN REACTIONS

Encode current GameState semantic structure exactly, but JSON-safe.

If internal structure is:

```text
girl_id → action/event reaction mapping
```

preserve every entry.

Do NOT rebuild known reactions from current content catalog.

Player knowledge is save state.

---

# 18. DATING EVENT HISTORY

Persist exactly:

```text
girl_played_dating_event_ids
girl_last_date_event_ids
```

because planner exclusions/cycle rules depend on them.

Do not clear event history on load.

---

# 19. WORLD / STORY STATE

Persist:

```json
{
  "unlocked_locations": [],
  "story_flags": {}
}
```

Even when many unlocks are stage-derived, preserve current canonical GameState state.

Story stage itself also saved separately.

On load, Story recomputes feature presentation from restored stage/flags.

---

# 20. SALARY STATE

Exact:

```json
"salary": {
  "initialized": false,
  "period_index": 0,
  "pending_salary": 0,
  "manual_cycle_seen": false,
  "advance_used_period": -1
}
```

No recalculation from Authority on load.

Restore saved pending Salary exactly.

---

# 21. MEDIA STATE

Exact logical fields:

```json
"media": {
  "photo_session_completed": false,
  "attention": 0,
  "photo_pose_by_shot": {},
  "published_photo_ids": [],
  "last_photo_publish_day": -1,
  "incoming_offer_girl_ids": [],
  "read_offer_girl_ids": [],
  "feed_event_ids": []
}
```

Preserve ordering of arrays.

---

# 22. DATING OVERLOAD REQUEST SERIALIZATION

Internal:

```text
DatingDemandEntry
```

must encode each request as plain Dictionary.

At minimum exact fields from actual `DatingDemandEntry`:

```text
request_id
girl_id
created_day
scheduled_day
slot
status
fulfilled_day
```

Cursor must audit current class and include ALL persistent fields actually present.

Do not save Resource paths.

---

# 23. DATING OVERLOAD BLOCK

```json
"dating_overload": {
  "started": false,
  "start_day": -1,
  "next_request_id": 1,
  "requests": [],
  "candidate_cursor": 0,
  "last_personal_date_day": -1,
  "personal_dates_completed": 0,
  "last_feed_boost_day": -1,
  "boost_pending": false,
  "problem_recognized": false
}
```

Restore request order.

---

# 24. CLONE STATE

Exact:

```json
"clones": {
  "total": 0,
  "working": 0,
  "dating": 0,
  "local_upgrade_production": 0,
  "local_upgrade_work": 0,
  "local_upgrade_dating": 0
}
```

Do NOT save:

```text
money_per_minute
dates_per_minute
```

as authoritative state.

Those are derived from:

```text
counts + local upgrades + global multipliers
```

After load:

```text
CloneIncremental.recalculate_rates()
```

must reproduce rates.

---

# 25. LATE GAME STATE

Exact:

```json
"late_game": {
  "world_reach": 0,
  "global_upgrade_production": 0,
  "global_upgrade_work": 0,
  "global_upgrade_dating": 0
}
```

Optional Stage6 one-shot manual events are already story flags and must remain there.

Do not duplicate them in LateGame payload.

---

# 26. FINAL COMPLETION

No separate:

```text
final_completed
```

persistent gameplay field.

Canonical truth remains:

```text
girl_final_target in conquered_girls
```

Slot metadata may derive:

```text
final_completed = is target conquered in payload
```

---

# 27. GAMEDAY

Separate root:

```text
game.game_day
```

Exact:

```json
{
  "current_day": 1
}
```

Add narrow restore API:

```gdscript
GameDay.restore_day(day: int)
```

Rules:

```text
day >= 1
```

Do NOT emit `day_advanced` during restore.

Add optional:

```text
day_restored
```

only if presentation needs it.

Gameplay must not interpret loading as a new day.

---

# 28. CLONEINCREMENTAL RUNTIME

This is the important state outside GameState.

Persist:

```json
"runtime": {
  "clone_incremental": {
    "production_elapsed_seconds": 0.0,
    "money_fraction": 0.0,
    "date_fraction": 0.0
  }
}
```

All three matter.

---

# 29. WHY FRACTIONS MUST SAVE

Without them:

```text
29.9 / 30 sec production
save/load
→ resets to0
```

and:

```text
0.99 Money/date fractional accumulation
→ lost
```

This makes saving alter incremental progress.

Therefore exact floats are persisted.

---

# 30. CLONEINCREMENTAL SAVE API

Add:

```gdscript
export_runtime_state() -> Dictionary
restore_runtime_state(data: Dictionary) -> bool
```

Validation:

```text
production_elapsed >=0
money_fraction >=0 and <1 after normalization
date_fraction >=0 and <1 after normalization
```

After restore:

```text
recalculate_rates()
_resolve_production_spawns()
```

Production elapsed may legitimately exceed the restored effective interval if schema/tuning changed; resolve all due clones safely.

---

# 31. LATEGAME RUNTIME

Current LateGameExpansion only has transient:

```text
_completion_emitted
```

Do NOT persist this bool.

After load derive:

```text
if world_reach >=100 / Story completion flag / stage FINALE
→ completion presentation should not fire again
```

Add narrow:

```text
sync_after_load()
```

that sets internal `_completion_emitted` from restored canonical state without re-triggering final transition.

---

# 32. OTHER TRANSIENT SYSTEMS NOT SAVED

Do NOT serialize active sessions:

```text
GirlDiscoveryAttempt
DatingSession
RivalEncounter active encounter
RivalCompetitionRunner active minigame
FirstClone active calibration/preview
PhotoSession active shot
CloneTerminal open state
GlobalTerminal open state
FinalDate attempt phase/score/rivals
tutorial queue currently displaying
HUD notification queue
music crossfade position
camera impulse
NPC visual animation
MODULE19 local visual actors
```

Save is forbidden while these matter.

---

# 33. STABLE SAVE POLICY

Manual game save allowed only when:

```text
World exists
World not busy
Player exists
Player control mode == GAMEPLAY
no active DatingCore session
no active Rival encounter/competition
no active GirlDiscovery attempt
no active FirstClone sequence
no active Media photo session
no active FinalDate attempt
```

If any condition fails:

```text
can_save = false
```

UI reason:

```text
Сейчас сохранить игру нельзя.
Заверши текущее действие.
```

---

# 34. WHY NO MID-ACTION SAVE

This avoids serializing transient orchestration such as:

```text
half of a date
current minigame timing
clone calibration pass
final-date Zone B checkpoint
```

TECH_PLAN asks full persistent game state, not save-any-frame architecture.

Stable-state save is the minimal reliable product solution.

---

# 35. LOAD POLICY

Load allowed from:

```text
Title Menu
PAUSED gameplay
```

Do NOT load over:

```text
active modal
active minigame
active final sequence
```

Pause menu is a safe boundary.

If current game is running:

```text
Load
→ confirmation
→ unpause
→ discard current transient scene state
→ restore selected save
```

---

# 36. SAVE VALIDATION BEFORE MUTATION

Load flow MUST:

1. read file;
2. parse JSON;
3. validate root/schema;
4. validate required types/ranges;
5. validate IDs where practical;
6. build in-memory normalized payload;
7. ONLY THEN mutate current game.

If validation fails:

```text
current game remains unchanged
```

---

# 37. CONTENT ID VALIDATION

For saved IDs:

```text
girl IDs
rival IDs
perk IDs
event IDs
location ID
```

Validate against current ContentDB where meaningful.

Unknown future/removed ordinary IDs:

Preferred rule:

- for non-critical historical IDs, skip with warning;
- for critical current world/story target IDs, reject or fallback safely.

Exact:

```text
saved current location unknown → fallback apartment
saved perk unknown → skip + warning
saved girl relationship unknown → skip + warning
saved story stage invalid → reject
```

Do not crash on removed MODULE25 content during later iteration.

---

# 38. BULK GAMESTATE RESTORE API

Do NOT have SaveSystem mutate private GameState members.

Add:

```gdscript
GameState.export_save_state() -> Dictionary
GameState.restore_save_state(data: Dictionary) -> bool
```

These own encode/decode of GameState persistent fields.

SaveSystem owns file/schema/orchestration.

This keeps GameState authority intact.

---

# 39. RESTORE MUST NOT USE GAMEPLAY GRANT APIs

Do NOT reconstruct by calling:

```text
add_experience(saved_xp)
buy perks
win rivals
complete girls
publish media
advance stage repeatedly
```

That would double side effects.

Use dedicated restore paths.

---

# 40. BULK RESTORE SIGNAL STRATEGY

Preferred:

```text
restore internal validated values
→ emit one semantic state_restored signal
```

Add:

```gdscript
signal state_restored()
```

Do NOT emit dozens of gameplay reward signals that trigger:

- HUD reward notifications;
- stage unlock jingles;
- story advancement;
- Reach gain;
- Media threshold processing.

Presentation/services refresh after `state_restored`.

---

# 41. EXISTING STATE_RESET

Load may begin with:

```text
GameState.reset_for_new_game()
```

BUT if using reset emits hooks that travel apartment or create transient presentation, orchestrate carefully.

Preferred:

```text
SaveSystem enters restoring mode
GameState.restore_save_state performs atomic replacement
state_restored
```

No fake new-game reset roundtrip required.

---

# 42. SERVICE SYNC AFTER LOAD — ORDER

After GameState payload is restored:

```text
1. GameDay.restore_day
2. CloneIncremental.restore_runtime_state
3. LateGameExpansion.sync_after_load
4. Story.sync_after_load / refresh current stage if needed
5. DatingOverload/Media refresh from GameState if they cache anything
6. World restore
7. presentation/UI refresh
```

Cursor must audit current service caches and only add sync methods where actually needed.

---

# 43. NO REPLAY OF GAMEPLAY EVENTS

Loading a save at:

```text
STAGE5
Scientist conquered
Lab unlocked
```

must NOT:

- award Scientist XP again;
- replay stage notification as a reward;
- regenerate overload wave;
- generate new media offer;
- complete world reach again;
- rerun first clone calibration.

Everything resumes from canonical state.

---

# 44. WORLD SAVE BLOCK

Root:

```text
world
```

Exact:

```json
{
  "location_id": "city_hub",
  "player": {
    "position": [0.0, 1.0, 2.0],
    "yaw": 0.0,
    "pitch": 0.0
  }
}
```

No Basis/Transform3D direct serialization.

---

# 45. PLAYER TRANSFORM

Persist:

```text
global_position x/y/z
yaw radians
pitch radians
```

Do NOT save:

```text
velocity
floor state
camera shake
control mode
interaction target
```

On load:

```text
velocity = ZERO
control mode = GAMEPLAY
```

---

# 46. EXACT POSITION VS SPAWN

Load should restore exact player pose when valid.

Flow:

1. load saved location using normal World scene validation;
2. place player at default spawn initially;
3. validate saved position;
4. apply saved position/yaw/pitch.

---

# 47. SAFE POSITION VALIDATION

Avoid restoring the player into invalid geometry.

After location load:

- ensure coordinates finite;
- ensure saved position not absurd (`length < sensible world bound`, e.g. 10,000m);
- test capsule occupancy if convenient with Player `test_move` / physics query.

If invalid:

```text
keep location default spawn
```

No save rejection.

---

# 48. LOCATION FALLBACK

If saved location scene is missing/invalid/unavailable after restored Story:

fallback:

```text
apartment
spawn_default
```

Log warning.

Do NOT fail entire save only because a location changed during development.

---

# 49. WORLD RESTORE API

Add narrow:

```gdscript
World.restore_saved_location(location_id, player_pose) -> WorldTravelResult
```

It may internally reuse:

```text
ensure_host
request_travel
```

but restore must not be blocked by temporary pre-load presentation order.

Access should be evaluated AFTER GameState/Story restored.

---

# 50. FIRSTCLONE RESTORE

First clone creation state is derived from:

```text
total_clones >= 1
```

Do NOT save FirstClone sequence bool.

On load in laboratory:

- if clones>=1, MODULE19 reconstructs aggregate visuals;
- no calibration prompt;
- first-clone machine says already created.

---

# 51. MODULE19 VISUAL RESTORE

No visual actor state saved.

After laboratory scene load:

```text
CloneVisualizationController
```

reconstructs from aggregate counts.

Test huge counts.

---

# 52. FINALDATE RESTORE

If final target conquered:

load in final_location:

```text
post-ending state
```

No final attempt.

If not conquered:

beacon available normally.

Because saves cannot occur mid-final attempt, no phase serialization.

---

# 53. AUTOSAVE POLICY

Autosave only after stable semantic milestones.

Exact triggers:

```text
World.location_changed
GameDay.day_advanced
GameState.stage_changed
GameState.girl_conquered
```

Plus:

```text
first clone persistent creation
```

when clone total first transitions:

```text
0 → >=1
```

Do NOT autosave on every later clone.

---

# 54. AUTOSAVE DEBOUNCE

Multiple milestone signals often fire together.

Use:

```text
0.75 sec debounce
```

Then one autosave.

If state becomes unstable during debounce:

wait until next safe gameplay opportunity.

Do not block gameplay.

No background thread required.

---

# 55. AUTOSAVE AFTER LOAD

Do NOT immediately overwrite autosave just because:

```text
location_changed
```

fires during restore.

SaveSystem has:

```text
_is_restoring
```

and ignores autosave triggers until restore complete.

---

# 56. MANUAL SAVE UI

Pause menu current functional overlay is expanded to:

```text
ПРОДОЛЖИТЬ
СОХРАНИТЬ
ЗАГРУЗИТЬ
НАСТРОЙКИ
В ГЛАВНОЕ МЕНЮ
```

Quit-to-desktop may also exist:

```text
ВЫЙТИ ИЗ ИГРЫ
```

but not required until MODULE28.

---

# 57. SAVE SCREEN

Three rows:

```text
СЛОТ 1
СЛОТ 2
СЛОТ 3
```

Each shows metadata.

Empty:

```text
ПУСТО
```

Click:

```text
Сохранить
```

Existing slot:

confirmation:

```text
Перезаписать сохранение?
[Да] [Нет]
```

---

# 58. LOAD SCREEN

Rows:

```text
АВТОСОХРАНЕНИЕ
СЛОТ 1
СЛОТ 2
СЛОТ 3
```

Only valid saves enabled.

Corrupt target + valid backup:

show:

```text
ВОССТАНОВЛЕНО ИЗ РЕЗЕРВНОЙ КОПИИ
```

Corrupt both:

```text
СОХРАНЕНИЕ ПОВРЕЖДЕНО
```

---

# 59. TITLE MENU

MODULE24 adds simple functional front-end.

At F5 launch, before World boot:

```text
DATE FACTORY

[Продолжить]
[Новая игра]
[Загрузить]
[Настройки]
[Выход]
```

No elaborate background needed.

---

# 60. CONTINUE

`Продолжить` enabled iff at least one valid save exists.

Choose newest valid by:

```text
saved_at_unix
```

among:

```text
autosave + manual slots
```

Load it.

---

# 61. NEW GAME

If any valid save exists:

confirmation:

```text
Начать новую игру?
Текущие сохранения не удалятся.
```

Important:

New Game does NOT delete manual slots or autosave immediately.

Flow:

```text
reset gameplay
GameDay day1
CloneIncremental runtime0
World apartment
```

Next autosave later replaces autosave.

Manual slots remain.

---

# 62. MAIN BOOT CHANGE

Current `main_bootstrap.gd` immediately calls:

```text
World.boot_from_main()
```

MODULE24 changes this.

New:

```text
main scene boots FrontEnd/MainMenu first
World has no active gameplay location until New/Continue/Load
```

Main bootstrap remains tiny.

Do NOT replace with generic scene-routing framework.

---

# 63. START GAME API

Preferred SaveSystem orchestration:

```text
start_new_game()
load_slot(slot)
continue_latest()
return_to_title()
```

FrontEnd UI calls these.

---

# 64. RETURN TO TITLE

From pause:

```text
В ГЛАВНОЕ МЕНЮ
```

If gameplay changed since last save:

confirmation:

```text
Несохранённый прогресс будет потерян.
```

You do not need perfect dirty-tracking.

Simpler:

always show confirmation while a game is active.

---

# 65. SETTINGS STORAGE

Settings use Godot:

```text
ConfigFile
```

Path:

```text
user://settings.cfg
```

Separate from game saves.

Settings apply even with no save.

---

# 66. SETTINGS SCHEMA

Config sections:

```text
[audio]
master
music
sfx
ui
ambience

[controls]
mouse_sensitivity
camera_feedback

[display]
fullscreen
vsync
fov
ui_scale

[tutorial]
seen
```

No legacy settings migration.

---

# 67. SETTINGS DEFAULTS

Exact defaults based on current project:

```text
master = 1.0
music = 1.0
sfx = 1.0
ui = 1.0
ambience = 1.0

mouse_sensitivity = 0.12
camera_feedback = 1.0

fullscreen = false
vsync = true
fov = 75.0
ui_scale = 1.0

tutorial seen = []
```

AudioDirector's bus baseline dB remains its asset/mix baseline.

User linear volumes multiply/control bus levels on top of existing semantics.

---

# 68. AUDIO SETTINGS

Five sliders:

```text
Общая громкость
Музыка
Эффекты
Интерфейс
Окружение
```

Range:

```text
0..100%
```

Apply immediately via current AudioDirector seams.

Persist immediately or on Apply.

Preferred:

```text
Apply button
```

for all settings together.

---

# 69. MOUSE SENSITIVITY

Current Player default:

```text
mouse_sensitivity_degrees = 0.12
```

Settings range:

```text
0.04 .. 0.30 degrees/pixel
```

UI displayed normalized:

```text
1..100
```

or decimal.

Preferred player-facing:

```text
Чувствительность мыши
```

slider with default marker.

Save actual float.

On player spawn/load:

```text
player.mouse_sensitivity_degrees = setting
```

---

# 70. FOV

Settings:

```text
60 .. 100
```

default75.

Player camera baseline changes to selected FOV.

CameraFeedback must update its baseline safely so pulses return to current configured FOV, not hardcoded75.

---

# 71. CAMERA FEEDBACK

Slider:

```text
Движение камеры
0 .. 100%
```

Maps:

```text
0.0..1.0
```

to current `CameraFeedback.set_feedback_scale`.

Default100%.

This is NOT general camera shake intensity beyond Module23 feedback.

---

# 72. UI SCALE

Exact choices:

```text
100%
125%
150%
```

Persist via:

```text
UiScaleHelper
```

Settings UI changing scale must apply to open settings/menu where practical.

If applying live causes layout instability, apply after screen rebuild, but no restart required.

---

# 73. FULLSCREEN

Exact options:

```text
Оконный
Полноэкранный
```

Use DisplayServer.

No borderless-exclusive taxonomy required.

Persist bool.

---

# 74. VSYNC

Exact:

```text
Вкл / Выкл
```

Use DisplayServer VSync mode.

Default:

```text
on
```

No FPS cap setting required.

---

# 75. RESOLUTION

Do NOT add arbitrary resolution picker in MODULE24.

Current stretch supports desktop window resizing.

Fullscreen uses monitor resolution.

Windowed project default:

```text
1280×720
```

Release pass may revisit if needed.

---

# 76. SETTINGS APPLY ORDER

On boot:

```text
1. load settings.cfg/defaults
2. apply display fullscreen/vsync
3. set UiScaleHelper current scale
4. AudioDirector on ready consumes volume settings
5. when Player exists:
   sensitivity/FOV/CameraFeedback scale
6. TutorialPrompt instance imports seen flags
```

---

# 77. SETTINGS CANCEL

Settings UI keeps working copy.

```text
Apply
Cancel
Defaults
```

`Cancel` restores previous runtime values if any were previewed.

Simpler preferred:

- audio may preview live;
- Cancel reapplies saved snapshot.

---

# 78. RESET DEFAULTS

Button:

```text
По умолчанию
```

sets UI controls to defaults.

Requires Apply to persist.

---

# 79. TUTORIAL SEEN PERSISTENCE

Current TutorialPrompt owns runtime `_seen`.

Add:

```gdscript
export_seen_ids() -> Array[int]
restore_seen_ids(ids: Array) -> void
```

Save under settings, NOT game slot.

Why:

tutorial preference is user-level, not character progression.

---

# 80. RESET TUTORIALS

Settings button:

```text
Сбросить подсказки
```

Clears seen IDs.

Persist settings.

Next relevant runtime triggers may show prompts again.

---

# 81. SAVE/SETTINGS ARE SEPARATE

Deleting/new game does NOT reset:

```text
audio
UI scale
camera feedback
mouse sensitivity
tutorial seen
display settings
```

Settings persist across game slots.

---

# 82. SAVE SLOT DELETE

Load/Save UI provides:

```text
[Удалить]
```

for manual slots.

Require confirmation.

Autosave may also have delete button from Load screen.

Deleting target also deletes its backup.

No trash/archive.

---

# 83. SAVE SUCCESS FEEDBACK

Manual save:

```text
ИГРА СОХРАНЕНА
```

small UI cue.

Autosave:

small unobtrusive icon/text:

```text
Автосохранение
```

for ~1 sec.

No full modal.

---

# 84. SAVE FAILURE FEEDBACK

Visible:

```text
Не удалось сохранить игру.
```

with technical details only in log.

Do not tell user save succeeded if write failed.

---

# 85. LOAD FAILURE FEEDBACK

Title/Pause load UI remains open and reports:

```text
Не удалось загрузить сохранение.
```

Current gameplay/title remains intact.

---

# 86. SETTINGS WRITE FAILURE

Runtime setting may remain applied for current session.

Show:

```text
Не удалось сохранить настройки.
```

Do not crash.

---

# 87. NO OFFLINE PROGRESS

Save contains:

```text
saved_at_unix
```

ONLY for metadata.

On load:

DO NOT calculate:

```text
now - saved_at
```

for clones/Money/dates.

MODULE18 no-offline rule remains exact.

---

# 88. SAVE TIMESTAMP

Use:

```text
Time.get_unix_time_from_system()
```

for metadata only.

Display local date/time using Godot Time APIs.

No timezone game logic.

---

# 89. GAME STATE VALIDATION — BASE RANGES

Reject impossible critical values:

```text
stage outside PROLOGUE..FINALE
Money <0
Authority <0
Experience <0
Upgrade Points <0
characteristic outside0..10
relationship outside -5..5
clone counts negative
working + dating > total
local upgrade outside0..5
Reach outside0..100
global upgrade outside0..3
GameDay <1
```

Non-critical collection item problems can be sanitized with warning.

---

# 90. EXPERIENCE / PERK CONSISTENCY

Do NOT require:

```text
Experience == spent UP + current UP
```

because global history/content may make strict reverse derivation brittle.

But characteristics must match purchased-perk counts per branch if current Progression contract guarantees it.

Preferred restore validation:

```text
characteristic level == purchased perk count in that branch
```

If mismatch:

reject save as corrupt rather than silently changing progression.

Cursor must confirm current perk content branch ownership.

---

# 91. CLONE RATE CONSISTENCY

Ignore saved rates entirely.

After restore derive.

Test:

saved payload attempts bogus:

```text
money_per_minute=999999
```

not even part of schema.

Actual service returns correct formula.

---

# 92. STORY CONSISTENCY

Do not attempt full theorem-proof validation of every Story state.

Minimum:

- stage enum valid;
- Story current definition exists;
- saved location has valid/derived access or fallback;
- final completion can coexist only with FINALE ideally.

If obviously impossible:

```text
final target conquered while stage<FINALE
```

reject critical corruption.

---

# 93. SAVE DURING ENDGAME

At FINALE after ending:

manual save allowed in GAMEPLAY.

Load:

```text
girl_final_target remains +5/conquered
Phone shows final complete
final location post-ending state
```

No repeated +1 XP.

---

# 94. SAVE BEFORE FIRST CLONE

Load Stage5 total0:

- President remains hidden;
- first clone machine usable;
- no CloneIncremental output until clone exists.

---

# 95. SAVE DURING OVERLOAD STABLE WORLD

Persist full request backlog/status/candidate cursor/boost.

Load same day:

- request IDs/statuses identical;
- no new wave generated;
- personal date cap state identical.

---

# 96. SAVE DURING MEDIA

Persist:

- selected photo poses;
- session completed;
- publications;
- Attention;
- incoming/read;
- feed.

If photo session currently ACTIVE:

manual save forbidden.

If stable after a shot selection but before session completion is represented as active photo session:

forbid save rather than serialize transient UI.

---

# 97. SAVE DURING CLONE INCREMENTAL

Example:

```text
production elapsed 29.5/30
money fraction .75
date fraction .40
```

Save/load.

Expected exact approximate resume.

No offline progress.

---

# 98. SAVE GLOBAL MULTIPLIER STATE

Stage6:

persist local/global upgrade levels and Reach.

Load:

`CloneIncremental` effective rates reflect restored global multipliers immediately.

---

# 99. AUTOSAVE + FRACTION TIMING

Autosave snapshot must read CloneIncremental accumulators in the same synchronous capture pass as GameState.

No multi-second asynchronous split.

---

# 100. SAVE CAPTURE CONSISTENCY

During payload capture:

temporarily block another SaveSystem capture.

Use:

```text
_is_saving
```

No need to pause game for full seconds.

Capture dictionaries synchronously in one frame.

File write is small.

---

# 101. SETTINGS MAIN MENU

Title Settings uses same:

```text
SettingsUI
```

scene as pause Settings.

No duplicate settings logic.

---

# 102. PAUSE CONTROL

Current Player pause sets:

```text
get_tree().paused = true
```

Pause UI / SaveSystem / Settings UI must use:

```text
PROCESS_MODE_WHEN_PAUSED
or ALWAYS
```

as appropriate.

Save screen must function while tree paused.

Clone simulation stays paused.

---

# 103. LOAD FROM PAUSE

When selected:

1. validate save;
2. set tree paused=false;
3. close pause/menu;
4. perform restore;
5. player ends GAMEPLAY.

No paused-state leak.

---

# 104. TITLE MUSIC

No new fifth music state.

Title may use:

```text
MANUAL
```

at reduced/default music volume.

Or silence.

Preferred:

```text
MANUAL
```

No new title music asset requirement.

---

# 105. FRONTEND UI THEME

Reuse:

```text
Date Factory Theme
```

from MODULE22.

No new visual language.

---

# 106. SAVE UI NUMBER FORMAT

Use existing:

```text
UiNumberFormat
```

for Money/clones.

Do not duplicate K/M/B formatting.

---

# 107. SAVE SCHEMA DOCUMENT

Create:

```text
docs/persistence/SAVE_SCHEMA_V1.md
```

It must list exact payload structure and ownership.

This document becomes canonical for future migration.

---

# 108. SETTINGS DOCUMENT

Same persistence architecture doc may include settings, or create:

```text
docs/persistence/SETTINGS.md
```

Keep concise.

---

# 109. SUGGESTED PROJECT AREA

```text
persistence/
├── save_system.gd
├── save_types.gd
├── save_slot_metadata.gd
├── save_result.gd
└── test/

ui/frontend/
├── main_menu.tscn
├── main_menu.gd
├── save_load_ui.tscn
├── save_load_ui.gd
├── settings_ui.tscn
└── settings_ui.gd
```

No files/classes unless actually useful.

---

# 110. RESULT TYPES

Typed `SaveResult`:

```text
ok
error
slot
message
recovered_from_backup
```

Errors:

```text
OK
BUSY
UNSAFE_STATE
FILE_NOT_FOUND
READ_FAILED
WRITE_FAILED
JSON_INVALID
UNSUPPORTED_SCHEMA
VALIDATION_FAILED
RESTORE_FAILED
```

Do not expose enum names directly in player UI.

---

# 111. SAVE SYSTEM SIGNALS

Recommended:

```text
save_started(slot)
save_completed(slot)
save_failed(slot, error)

load_started(slot)
load_completed(slot)
load_failed(slot, error)

settings_applied()
autosave_completed()
```

No EventBus.

---

# 112. TEST — EMPTY INSTALL

No saves/settings.

Boot:

```text
Main Menu
Continue disabled
New Game enabled
defaults applied
```

New Game:

```text
PROLOGUE
Day1
apartment
```

---

# 113. TEST — MANUAL SLOT ROUNDTRIP

Set representative midgame state with:

- Stage3;
- Money;
- Authority;
- XP/UP;
- perks;
- two girls relationships/history;
- defeated rivals;
- salary.

Save slot1.

Mutate state heavily.

Load slot1.

Every persisted value exact.

---

# 114. TEST — ALL GAMESTATE COLLECTIONS

Explicit roundtrip test for every collection:

```text
conquered
discovered
contacts
clues
trait reveals
known reactions
retry days
cooldowns
played events
last events
locations
story flags
```

Missing one collection is blocker.

---

# 115. TEST — MEDIA ROUNDTRIP

Save complex Media state.

Restore exact arrays/maps/day/Attention.

No threshold-generated duplicates after load.

---

# 116. TEST — OVERLOAD ROUNDTRIP

At least:

```text
7 generated demands
mix WAITING/OVERDUE/FULFILLED
candidate cursor nonzero
boost pending true
recognized true
```

Roundtrip exact.

No new request IDs collision after continuing.

---

# 117. TEST — CLONE ROUNDTRIP

Example:

```text
total27
work9
dating14
free4
local levels4/2/5
global levels2/1/3
Reach68

production_elapsed1.73
money_fraction.42
date_fraction.87
```

Roundtrip.

Derived rates exact.

---

# 118. TEST — NO OFFLINE

Save.

Artificially change save timestamp to yesterday.

Load.

Expected:

```text
no extra clones
no extra Money
no extra dates
```

Only fractional state restored.

---

# 119. TEST — WORLD LOCATION

Save in every canonical location:

```text
apartment
city_hub
cafe
gym
appearance_space
salary_mine
laboratory
production_area
final_location
```

with valid story state.

Load each.

Correct scene + approximate/exact player pose.

---

# 120. TEST — INVALID PLAYER POSITION

Corrupt saved player position inside invalid/absurd coordinates.

Load:

```text
location loads
player at default spawn
game works
```

No crash.

---

# 121. TEST — UNKNOWN LOCATION

Edit save location:

```text
removed_location
```

Load:

```text
apartment fallback
rest of state preserved
```

---

# 122. TEST — ACTIVE DATE SAVE BLOCK

During DatingUI:

manual Save unavailable/rejected.

After date completes and GAMEPLAY:

allowed.

---

# 123. TEST — ACTIVE MINIGAME SAVE BLOCK

All rival minigames:

save rejected.

Pause if allowed:

Save remains disabled if underlying active minigame.

---

# 124. TEST — FINAL ATTEMPT SAVE BLOCK

During walking GAMEPLAY phase inside active FinalDate attempt:

Save MUST still be rejected.

This catches the case where control mode alone would incorrectly allow it.

---

# 125. TEST — FIRST CLONE SAVE BLOCK

During calibration/preview/assignment:

rejected.

After assignment commits and sequence ends:

allowed/autosave.

---

# 126. TEST — CORRUPT PRIMARY / VALID BACKUP

Damage slot JSON.

Load:

backup used.

UI marks recovered.

Gameplay correct.

---

# 127. TEST — BOTH CORRUPT

No state mutation.

Visible failure.

---

# 128. TEST — UNSUPPORTED VERSION

Set:

```text
schema_version = 999
```

Reject.

No legacy/migration attempt.

---

# 129. TEST — INVALID CRITICAL RANGE

Examples:

```text
stage99
relationship20
working>total
Day0
```

Reject before mutation.

---

# 130. TEST — UNKNOWN ORDINARY CONTENT IDS

Put removed ordinary girl in historical contact array.

Expected:

```text
sanitize/skip with warning
save otherwise loads
```

Put invalid stage:

reject.

---

# 131. TEST — AUTOSAVE DEBOUNCE

Stage change + girl conquest + location travel close together:

```text
one autosave
```

not three writes.

---

# 132. TEST — NO AUTOSAVE DURING RESTORE

Load triggers location/stage refresh signals.

Expected:

```text
autosave file not immediately overwritten
```

---

# 133. TEST — NEW GAME PRESERVES MANUAL SAVES

Have slot1.

New Game.

Slot1 remains.

Game state reset.

---

# 134. TEST — SETTINGS WITHOUT SAVE

Fresh install:

change Music/UI scale.

Restart app.

Settings persist even without any game save.

---

# 135. TEST — AUDIO SETTINGS

Set:

```text
Master0
Music25
SFX70
UI40
Ambience10
```

Apply/restart.

AudioDirector reports/applies expected values.

No log errors.

---

# 136. TEST — CAMERA FEEDBACK SETTING

Set0.

Restart/load.

Slap camera motion zero.

Set100.

Restored normal caps.

---

# 137. TEST — MOUSE SENSITIVITY

Change setting.

Newly spawned Player and existing Player both use saved value.

Restart preserves.

---

# 138. TEST — FOV

Set90.

Camera baseline90.

Slap/clone FOV pulse returns exactly90.

Restart90.

---

# 139. TEST — UI SCALE

Set150.

Restart/title + gameplay UI remain150.

Set100.

Correct.

---

# 140. TEST — FULLSCREEN / VSYNC

Apply.

Restart.

Display modes reflect settings.

No requirement for headless CI to truly open fullscreen; wrap display calls safely in headless tests.

---

# 141. TEST — TUTORIAL PERSISTENCE

See FIRST_PHONE.

Restart New Game.

FIRST_PHONE remains seen.

Reset Tutorials.

Trigger again:

shows.

---

# 142. TEST — ENDING ROUNDTRIP

Complete game.

Save slot3.

Restart/Load.

Expected:

```text
FINALE
girl_final_target +5/conquered
XP preserved
world Reach100
post-ending Phone
final location/world state functional
no reward duplicate
```

---

# 143. TEST — LOAD OLD SAVE AFTER CONTENT MODULE25

Schema remains v1.

MODULE25 adds ordinary content.

Existing v1 saves still load because additive content does not require migration.

This is an architectural acceptance goal.

---

# 144. FULL F5 SAVE/LOAD ACCEPTANCE

Required production run with multiple restarts.

## Early

```text
New Game
→ Actress progress
→ save slot1
→ restart app
→ Continue
→ same world/story/progression
```

## Media

```text
Stage4 with Attention/incoming/backlog
→ manual save
→ restart/load
→ exact Media/Overload state
```

## Clone

```text
clones/rates/fractions
→ save
→ restart/load
→ same counts/rates/fractional progress
```

## Late

```text
Stage6 Reach/upgrades
→ save
→ restart/load
→ continue to FINALE
```

## Ending

```text
complete ending
→ save
→ restart/load
→ post-ending state
```

No debug reconstruction.

---

# 145. DOCUMENTATION

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/ui/UI_ARCHITECTURE.md
docs/presentation/PRESENTATION_ARCHITECTURE.md
```

Create:

```text
docs/persistence/SAVE_SCHEMA_V1.md
docs/persistence/PERSISTENCE_ARCHITECTURE.md
```

Document:

- SaveSystem ownership;
- stable-save policy;
- slots/autosave/backups;
- schema version;
- no legacy migration;
- no offline progress;
- GameState state list;
- CloneIncremental fractional runtime;
- world restore;
- settings;
- tutorial persistence.

---

# 146. TECHNICAL DECISION — SAVE BOUNDARY

Document exact:

```text
Date Factory v2 saves stable persistent state only.
Transient active dates/minigames/first-clone/final-date attempts are not serializable.
Manual save is disabled until the player returns to a stable GAMEPLAY state.
```

---

# 147. TECHNICAL DECISION — DERIVED STATE

Do NOT persist derived:

```text
Money/min
Dates/min
Story feature unlock cache
MODULE19 visual actors
music state
UI state
current animation
```

Recompute/reconstruct.

---

# 148. TECHNICAL DECISION — SETTINGS

Settings are:

```text
user-level
separate from save slots
ConfigFile
apply on boot
```

Tutorial seen IDs are settings.

---

# 149. WHAT MODULE24 DOES NOT IMPLEMENT

Do NOT implement:

- Steam Cloud;
- cloud conflict resolution;
- legacy-v1 save migration;
- save encryption;
- compression;
- binary custom format;
- per-frame rewind;
- mid-date serialization;
- minigame serialization;
- FinalDate checkpoint saves;
- offline income;
- screenshot thumbnails;
- multiple player profiles;
- key rebinding;
- controller mapping;
- language/localization selector;
- arbitrary resolution list;
- graphics quality presets;
- Steam Deck special settings;
- achievements;
- release build packaging.

---

# 150. DEFINITION OF DONE

MODULE24 complete only if:

- [ ] one `SaveSystem` autoload exists;
- [ ] autoload sits before AudioDirector;
- [ ] schema version exactly1;
- [ ] 3 manual slots + autosave;
- [ ] `user://saves/` paths exact;
- [ ] JSON game saves;
- [ ] atomic temp-write;
- [ ] one backup per slot;
- [ ] corrupt primary falls back to valid backup;
- [ ] corrupt both fail without state mutation;
- [ ] unsupported schema rejected;
- [ ] all GameState persistent fields serialized;
- [ ] all girl knowledge/history serialized;
- [ ] salary state serialized;
- [ ] Media state serialized;
- [ ] DatingOverload requests and counters serialized;
- [ ] clone counts/local upgrades serialized;
- [ ] world Reach/global upgrades serialized;
- [ ] late rates are NOT authoritative persisted state;
- [ ] GameDay persisted;
- [ ] CloneIncremental three runtime accumulators persisted;
- [ ] no offline progress;
- [ ] LateGame completion presentation sync does not replay;
- [ ] transient active sessions are not persisted;
- [ ] manual save only in stable state;
- [ ] FinalDate walking gameplay still blocks save;
- [ ] load validates fully before mutation;
- [ ] GameState has controlled bulk export/restore API;
- [ ] restore does not replay gameplay reward APIs;
- [ ] service refresh after load is deterministic;
- [ ] current location persisted;
- [ ] player position/yaw/pitch persisted;
- [ ] invalid position falls back to spawn;
- [ ] unknown location falls back apartment;
- [ ] MODULE19 visuals reconstruct rather than save;
- [ ] final completion derives from conquered final girl;
- [ ] autosave on location/day/stage/girl conquest/first clone;
- [ ] autosave debounced0.75s;
- [ ] no autosave feedback spam;
- [ ] restore does not trigger autosave;
- [ ] title Main Menu exists;
- [ ] Continue/New/Load/Settings/Exit buttons exist;
- [ ] Continue chooses newest valid save;
- [ ] New Game does not delete manual saves;
- [ ] pause Save/Load/Settings/Main Menu exists;
- [ ] Settings use separate `user://settings.cfg`;
- [ ] five audio volume settings persist;
- [ ] mouse sensitivity persists;
- [ ] FOV persists;
- [ ] camera feedback scale persists;
- [ ] UI scale100/125/150 persists;
- [ ] fullscreen/vsync persist;
- [ ] Tutorial seen IDs persist as settings;
- [ ] Reset Tutorials works;
- [ ] settings apply without game save;
- [ ] FOV feedback baseline remains correct;
- [ ] full early/media/clone/late/ending restart tests pass;
- [ ] all MODULE02–23 regressions PASS;
- [ ] no MODULE25 content implemented ahead.

---

# 151. RECOMMENDED CURSOR ORDER

```text
1. Audit every current persistent GameState field and every service-local runtime field.
2. Implement SaveTypes/SaveResult/metadata and JSON schema validator.
3. Add GameState export_save_state / restore_save_state with exhaustive tests.
4. Add GameDay restore.
5. Add CloneIncremental runtime export/restore.
6. Add LateGame/service sync-after-load seams where actually needed.
7. Implement SaveSystem slot I/O, atomic temp + backup recovery.
8. Implement world/player pose capture/restore.
9. Add stable-state guard covering Dating/Rivals/Discovery/FirstClone/Photo/FinalDate.
10. Add autosave triggers + debounce + restore suppression.
11. Refactor main bootstrap to functional title menu before World boot.
12. Expand pause menu with Save/Load/Settings/Main Menu.
13. Implement Settings ConfigFile + runtime application.
14. Persist tutorial seen IDs.
15. Corruption/schema/roundtrip automated tests.
16. Full multi-restart F5 route early→Media→Clone→Late→Ending.
17. All regressions/docs.
```

---

# 152. CURSOR FINAL REPORT

## Persistence architecture

Confirm:

```text
SaveSystem
schema v1
3 manual + autosave
JSON
atomic temp write
backup recovery
```

## Exhaustive state

List every GameState group actually serialized.

Explicitly confirm:

```text
girls/history
salary
Media
DatingOverload
clones/upgrades
Reach/global
```

## Runtime state

Confirm:

```text
GameDay
CloneIncremental:
 production_elapsed
 money_fraction
 date_fraction
```

and no offline simulation.

## Stable-save boundary

Show every active system that blocks save, especially:

```text
FinalDate active while Player is GAMEPLAY
```

## World

Confirm location + player pose restore and fallbacks.

## Settings

Confirm:

```text
5 audio sliders
mouse sensitivity
FOV
camera feedback
UI scale
fullscreen
vsync
tutorial seen
```

## Front-end

Show:

```text
Main Menu
Continue
New Game
Load
Settings
Pause Save/Load
```

## Recovery

Demonstrate:
- corrupt primary → backup;
- unsupported schema → safe failure;
- load failure does not mutate current game.

## Full game

Describe multiple real restart/load checkpoints through ending.

## Regressions

All MODULE02–23 suites.

## Commit

SHA.

Then STOP. Do not begin MODULE25.
