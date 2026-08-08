# Save Architecture — MODULE 24

**Статус:** реализованная persistence architecture после MODULE 24.  
**Граница:** один autoload `SaveSystem` — slots / autosave / schema / settings. Gameplay остаётся source of truth; SaveSystem только encode / validate / restore.  
**STOP:** без MODULE 25 content completion; без legacy migration / cloud / encryption / mid-minigame saves.

Spec: `docs/modules/MODULE_24_SAVE_LOAD_SETTINGS.md`.  
UI front-end: `docs/ui/UI_ARCHITECTURE.md`.  
Presentation seams: `docs/presentation/PRESENTATION_ARCHITECTURE.md`.

---

## 1. Ownership

| Concern | Owner | Path |
|---|---|---|
| Slots + autosave + settings | autoload `SaveSystem` | `persistence/save_system.gd` |
| Schema constants / paths | `SaveTypes` | `persistence/save_types.gd` |
| Typed I/O result | `SaveResult` | `persistence/save_result.gd` |
| Slot list cards | `SaveSlotMetadata` | `persistence/save_slot_metadata.gd` |
| Domain blob | `GameState.export_save_state` / `restore_save_state` | `game/state/game_state.gd` |
| Day index | `GameDay.restore_day` | `game/day/game_day.gd` |
| Clone fractions | `CloneIncremental.export_runtime_state` / `restore_runtime_state` | `game/clone_incremental/clone_incremental.gd` |
| Location + pose | `World.export_world_save_state` / `restore_saved_location` | `world/world.gd` |
| Title / Pause / Settings UI | presentation only | `ui/frontend/*` |

Не создаются: `SaveManager`, `SettingsManager`, `ProfileManager`, EventBus persistence, Resource `.tres` saves.

---

## 2. Autoload order

```text
… → LateGameExpansion → SaveSystem → AudioDirector
```

`SaveSystem._ready()` loads `user://settings.cfg` and applies display/UI scale before deferred audio/player seams. `AudioDirector` may receive volumes after its own `_ready` via deferred `_apply_audio_settings`.

---

## 3. Files

| Path | Role |
|---|---|
| `user://saves/slot_1.json` … `slot_3.json` | Manual slots (`SaveTypes.Slot.MANUAL_1..3`) |
| `user://saves/autosave.json` | Autosave (`Slot.AUTOSAVE = 0`) |
| `user://saves/*.bak.json` | Previous good file (atomic rename backup) |
| `user://saves/*.tmp` | Write staging; removed after rename |
| `user://settings.cfg` | ConfigFile settings (not in JSON save) |

No save files under `res://`.

---

## 4. Schema v1

`SaveTypes.SAVE_SCHEMA_VERSION = 1`.

Root JSON:

```json
{
  "schema_version": 1,
  "saved_at_unix": 0,
  "game": {
    "game_state": {},
    "game_day": { "current_day": 1 }
  },
  "world": {
    "location_id": "apartment",
    "player": {
      "position": [0.0, 0.0, 0.0],
      "yaw": 0.0,
      "pitch": 0.0
    }
  },
  "runtime": {
    "clone_incremental": {
      "production_elapsed_seconds": 0.0,
      "money_fraction": 0.0,
      "date_fraction": 0.0
    }
  }
}
```

- `schema_version != 1` → `UNSUPPORTED_SCHEMA` (no legacy / donor migration).
- JSON text only — not Godot Resource serialization.

### `game.game_state` (required top keys)

`stage`, `money`, `authority`, `experience`, `upgrade_points`, `characteristics`, `purchased_perks`, `defeated_rivals`, `girls`, `unlocked_locations`, `story_flags`, `salary`, `media`, `dating_overload`, `clones`, `late_game`.

Owned entirely by `GameState` export/restore. Services (`Story`, `Media`, `DatingOverload`, `LateGameExpansion`) re-sync after restore via `sync_after_load` where present.

### CloneIncremental fractions

Runtime-only progress **not** in GameState aggregates:

- `production_elapsed_seconds` — free-clone timer;
- `money_fraction` / `date_fraction` — sub-unit accrual in `[0, 1)` after normalize.

Restored before world travel; then rates recalculated.

### World pose

`World` exports `location_id` + player pose. Restore: travel (access from restored Story) → apply pose if safe → else keep spawn; bad location falls back to apartment. Pose failure does not wipe domain state.

---

## 5. Atomic write + backup

`_atomic_write_text`:

1. Write `target.tmp`;
2. If target exists → rename/copy to `*.bak.json`;
3. Rename/copy tmp → target.

Load: prefer primary JSON; if corrupt/missing → try `.bak.json` and set `recovered_from_backup` on `SaveResult` / metadata.

---

## 6. Save / load API

| API | Notes |
|---|---|
| `save_slot(slot)` | Manual requires `can_save_now()`; autosave blocked only while restoring |
| `autosave()` / `request_autosave()` | Debounce `0.75 s`; retries while unsafe |
| `load_slot(slot)` | Validate → restore GameState → GameDay → CloneIncremental → sync services → World |
| `continue_latest()` | Newest valid among 3 manual + autosave by `saved_at_unix` |
| `start_new_game()` | Fresh domain state + apartment; does **not** wipe existing slot files |
| `delete_slot(slot)` | Removes primary + bak |
| `return_to_title()` | `World.prepare_for_title()`; title UI owns presentation |
| `can_save_now()` | Safe in `GAMEPLAY` or `PAUSED`; blocks MODAL_UI / MINIGAME / active date / rival / discovery / first-clone sequence / photo session / FinalDate attempt / World busy |

Signals: `save_*`, `load_*`, `settings_applied`, `autosave_completed`.

### Autosave milestones (debounced)

`stage_changed`, `girl_conquered`, `day_advanced`, `location_changed`, first time `total_clones >= 1`. No per-tick / every-clone spam. Suppressed while `_is_restoring`.

---

## 7. Settings (`user://settings.cfg`)

Separate from game JSON. Defaults + clamps in `SaveSystem`.

| Section | Keys |
|---|---|
| `audio` | `master` `music` `sfx` `ui` `ambience` (0..1) → `AudioDirector` |
| `controls` | `mouse_sensitivity` (0.04..0.30), `camera_feedback` (0..1) → player / `CameraFeedback` |
| `display` | `fullscreen`, `vsync`, `fov` (60..100), `ui_scale` (1.0 / 1.25 / 1.5) |
| `tutorial` | `seen` (`PackedStringArray` of prompt ids) |

`apply_settings` merges, applies, writes cfg, emits `settings_applied`. Boot applies display immediately; audio/player deferred until nodes exist.

---

## 8. Front-end (presentation)

| Surface | Path |
|---|---|
| Title | `ui/frontend/title_menu.tscn` + `.gd` — Continue / New Game / Load / Settings |
| Pause | `ui/frontend/pause_menu.tscn` + `.gd` — Save / Load / Settings / Title |
| Settings | `ui/frontend/settings_panel.tscn` + `.gd` |
| Thin API | `ui/frontend/frontend_save_api.gd` (`FrontendSaveApi`) |

`main_bootstrap` → `World.prepare_for_title` → spawn `TitleMenu` (no immediate apartment travel). Pause enters `ControlMode.PAUSED` so manual save remains allowed.

---

## 9. Explicit non-goals

- Legacy-v1 / donor save migration  
- Steam Cloud, encryption, multi-profile  
- Mid-date / mid-minigame / mid-FinalDate saves  
- Offline clone catch-up beyond restored fractions  
- MODULE 25 content packs  

---

## 10. Tests

| Runner | Path |
|---|---|
| SaveSystem | `persistence/test/save_system_self_test.tscn` |
| GameState save | `game/state/test/game_state_save_self_test.tscn` |
| World pose | `world/test/world_save_pose_self_test.gd` |
