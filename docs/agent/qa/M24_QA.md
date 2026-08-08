# M24_QA — MODULE 24 Independent QA

**Task:** M24_H_QA  
**Module:** 24 — Save / Load / Settings  
**Date:** 2026-08-08  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  
**Evidence:** `tmp/m24_qa/`  
**DoD:** `docs/modules/MODULE_24_SAVE_LOAD_SETTINGS.md` + `docs/agent/ACCEPTANCE.md`

## Verdict

**PASS** → recommend **READY**

Independent headless regressions (SaveSystem / GameState domain / world pose + MODULE 02/09/18/20/21/22/23 sample) all EXIT=0. Indep harness `passed=51 failed=0` (windowed; headless `45/0` without shots). Title Continue disabled when empty; New Game → apartment; midgame slot roundtrip; settings.cfg persist across slot wipe; corrupt primary → bak recovery; unsupported schema rejected; SaveSystem before AudioDirector; no MODULE25. Screenshots opened and described; visual WARNINGs only (settings clip, dim pause backdrop).

---

## 1. Summary

| Area | Result |
|------|--------|
| `save_system_self_test` | PASS — `ALL PASS (57)` EXIT=0 |
| `game_state_save_self_test` | PASS — `ALL PASS (88)` EXIT=0 |
| `world_save_pose_test` | PASS — `ALL PASS (28)` EXIT=0 |
| MODULE02 `game_state_test` | PASS — `ALL PASS (131)` EXIT=0 |
| MODULE09 dating | PASS — `ALL PASS (163)` EXIT=0 |
| MODULE18 clone_incremental | PASS — `ALL PASS (110)` EXIT=0 |
| MODULE20 late_game | PASS — `ALL PASS (101)` EXIT=0 |
| MODULE21 final_date | PASS — `ALL PASS (78)` EXIT=0 |
| MODULE22 content_data (`content_data_test`) | PASS — `ALL PASS (139)` EXIT=0 |
| MODULE23 audio_director | PASS — `ALL PASS (31)` EXIT=0 |
| Indep harness (title/new/save/settings/bak/schema) | PASS — headless 45/0; windowed 51/0 |
| Screenshots (QA opened each) | PASS with visual WARNINGs |
| SaveSystem before AudioDirector | PASS |
| No MODULE25 | PASS |
| No SCRIPT/Parse errors in suite logs | PASS |

---

## 2. Criteria

| Criterion | Status | Evidence | Reproduction |
|-----------|--------|----------|--------------|
| SaveSystem schema v1 | PASS | `SAVE_SCHEMA_VERSION == 1`; self-test + indep | Headless + indep |
| 3 manual + autosave + atomic/bak | PASS | `MODULE_24_SAVE_IO_TEST ALL PASS (57)`; indep bak path | `save_system_self_test` + indep |
| GameState exhaustive + GameDay + clone fractions | PASS | Domain `ALL PASS (88)` | `game_state_save_self_test` |
| World / player pose restore | PASS | World `ALL PASS (28)` | `world_save_pose_test` |
| Settings persist independently | PASS | `user://settings.cfg`; survive slot wipe | Indep `_test_settings_persist` |
| Title Continue disabled when empty | PASS | Button disabled; shot `01_title_menu.png` | Indep + screenshot |
| New Game → apartment | PASS | `current_location_id == apartment` | Indep |
| Midgame save slot roundtrip | PASS | money/auth/stage 777/2/2 restored | Indep |
| Corrupt primary → bak | PASS | `recovered_from_backup`; money 321 | Indep |
| Unsupported schema rejected | PASS | `UNSUPPORTED_SCHEMA` | Indep edge |
| Pause Save/Load/Settings present | PASS | Shot `03_pause_menu.png` (Сохранить/Загрузить/Настройки) | Windowed indep |
| Autoload SaveSystem before AudioDirector | PASS | `project.godot` lines 38–40 | Read project.godot |
| MODULE 02/09/18/20/21/22/23 sample | PASS | All EXIT=0 ALL PASS | Headless suite |
| No MODULE25 | PASS | No `MODULE_25*` files | Filesystem + indep |
| No SCRIPT/Parse errors | PASS | Grep across `tmp/m24_qa/*.log` empty | Suite |
| Screenshots match names | PASS with WARNING | See §4 | Windowed indep |

### Edge cases exercised

1. Corrupt primary JSON → valid `.bak.json` recovery (`recovered_from_backup`).  
2. `schema_version=99` without bak → load rejected `UNSUPPORTED_SCHEMA` (no silent New Game).

---

## 3. Commands executed

```powershell
$godot = "C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe"

# Headless M24 + MODULE sample (logs under tmp/m24_qa/*.log)
& $godot --path . --headless --quit-after 60000 res://persistence/test/save_system_self_test.tscn
& $godot --path . --headless --quit-after 60000 res://game/state/test/game_state_save_self_test.tscn
& $godot --path . --headless --quit-after 60000 res://world/test/world_save_pose_test.tscn
& $godot --path . --headless --quit-after 60000 res://world/test/game_state_test.tscn
& $godot --path . --headless --quit-after 90000 res://game/dating/test/dating_test.tscn
& $godot --path . --headless --quit-after 90000 res://game/clone_incremental/test/clone_incremental_test.tscn
& $godot --path . --headless --quit-after 90000 res://game/late_game/test/late_game_test.tscn
& $godot --path . --headless --quit-after 90000 res://game/final_date/test/final_date_test.tscn
& $godot --path . --headless --quit-after 60000 res://world/test/content_data_test.tscn
& $godot --path . --headless --quit-after 60000 res://audio/test/audio_director_self_test.tscn

# Indep harness
& $godot --path . --headless --quit-after 120000 res://tmp/m24_qa/m24_indep_qa.tscn
& $godot --path . --quit-after 0 res://tmp/m24_qa/m24_indep_qa.tscn
```

Godot CLI: `C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe`  
Note: `--quit-after` is **frames/iterations** (not seconds); windowed harness used `--quit-after 0` (disabled).

---

## 4. Screenshots — paths + factual content (QA opened each)

| File | Claimed | Actual content (opened) | Match |
|------|---------|-------------------------|-------|
| `tmp/m24_qa/01_title_menu.png` | Title menu | Centered dark panel: **DATE FACTORY** / «Главное меню»; buttons Продолжить (greyed/disabled), Новая игра (focused), Загрузить, Настройки, Выход; two-tone dark brown/blue backdrop | PASS |
| `tmp/m24_qa/02_settings.png` | Settings | Title still behind; right overlay **НАСТРОЙКИ** with Master/Music/SFX/UI/Ambience sliders (~80/80/100/100/100) + mouse sensitivity label; scrollbar; Continue still disabled | PASS with WARNING — lower options clipped by panel height |
| `tmp/m24_qa/03_pause_menu.png` | Pause menu | Center **ПАУЗА** with Продолжить / Сохранить / Загрузить / Настройки / В главное меню / Выйти из игры; top-left HUD `$ 0` / АВТОРИТЕТ 0 / ОПЫТНОСТЬ 0 / БАЛЛЫ 0; dark dim backdrop | PASS with WARNING — apartment geometry not clearly visible behind UI |

---

## 5. Indep harness detail

| Check | Result |
|-------|--------|
| Continue disabled when empty | PASS |
| New Game → apartment | PASS |
| MANUAL_1 midgame money/auth/stage roundtrip | PASS (777/2/2) |
| Continue enabled after valid save | PASS |
| settings.cfg write + reload | PASS |
| Settings survive slot wipe | PASS |
| Corrupt MANUAL_2 → bak | PASS (`recovered_from_backup`, money 321) |
| Unsupported schema MANUAL_3 | PASS |
| No MODULE25 paths | PASS |
| Autoload order in `project.godot` | PASS |

Report journal: `tmp/m24_qa/m24_indep_qa_report.txt`  
Raw logs: `tmp/m24_qa/m24_indep_qa_headless.log`, `tmp/m24_qa/m24_indep_qa_windowed.log`

---

## 6. Autoload order

Confirmed in `project.godot`:

```text
LateGameExpansion=...
SaveSystem=*res://persistence/save_system.gd
AudioDirector=*res://audio/audio_director.gd
```

Boot logs show `[DF][MODULE_24] SaveSystem ready` before gameplay tests; AudioDirector remains after SaveSystem.

---

## 7. Non-blocking issues

1. **Settings panel clip (WARNING):** Mouse sensitivity / remaining display toggles require scroll; lower controls partially cut off in `02_settings.png`.  
2. **Pause backdrop dim (WARNING):** `03_pause_menu.png` shows pause + HUD correctly, but world behind is near-void dark (not a clear apartment landmark).  
3. **Exit-time RID/ObjectDB leaks:** Present across headless/windowed runs (same class of engine teardown noise seen in prior modules); no SCRIPT/Parse errors and EXIT=0.  
4. **Expected validation `push_error` noise:** MODULE02 / domain tests intentionally exercise reject paths (negative money, day=0, etc.) — not runtime failures of the product path.

---

## 8. MODULE25 check

- No `MODULE_25*` docs/content/product start found.  
- QA did not begin MODULE25 work.

---

## 9. Blocking issues

None.

---

## Overall status

**PASS** → **READY**

## Blocking issues

None.

## Non-blocking issues

- Settings overlay vertical clip (scrollbar needed for lower rows).  
- Pause screenshot backdrop poorly readable (dark).  
- Exit RID/resource leak noise (non-critical).

## Evidence

- Logs: `tmp/m24_qa/*.log`, `tmp/m24_qa/suite_summary.txt`  
- Indep: `tmp/m24_qa/m24_indep_qa_headless.log`, `m24_indep_qa_windowed.log`, `m24_indep_qa_report.txt`  
- Screenshots: `tmp/m24_qa/01_title_menu.png`, `02_settings.png`, `03_pause_menu.png`  
- Harness: `tmp/m24_qa/m24_indep_qa.tscn` + `.gd`  
- This report: `docs/agent/qa/M24_QA.md`

## Reproduction steps

1. Run headless suite commands in §3; expect all EXIT=0 and ALL PASS lines in `tmp/m24_qa/suite_summary.txt`.  
2. Run windowed indep:  
   `Godot_v4.7.1-stable_win64_console.exe --path . --quit-after 0 res://tmp/m24_qa/m24_indep_qa.tscn`  
   Expect `DONE passed=51 failed=0` and three PNGs under `tmp/m24_qa/`.  
3. Open PNGs and confirm title Continue disabled, settings overlay, pause Save/Load/Settings.
