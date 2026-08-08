# M23_QA — MODULE 23 Independent QA

**Task:** M23_H_QA  
**Module:** 23 — Audio / Animation / Feedback  
**Date:** 2026-08-08  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  
**Evidence:** `tmp/m23_qa/`  
**DoD:** `docs/modules/MODULE_23_AUDIO_ANIMATION_FEEDBACK.md` + `docs/agent/ACCEPTANCE.md`

## Verdict

**PASS** → recommend **READY**

Independent headless regressions (MODULE 03–22 sample + M23 audio/camera) all EXIT=0. Indep harness `passed=45 failed=0` (headless + windowed). Buses, stage→music MANUAL/MEDIA/CLONE/FINAL, same-state no restart, duck restore, 100 money ticks → 0 SFX, CameraFeedback scale0 zero motion, no donor runtime paths, no MODULE24 settings/persistence. Screenshots captured; visual WARNINGs only (debug overlay + weak final “beacon” framing).

---

## 1. Summary

| Area | Result |
|------|--------|
| `audio_director_self_test` | PASS — `ALL PASS (31)` EXIT=0 |
| `camera_feedback_self_test` (`tmp/m23_d`) | PASS — `ALL PASS (7)` EXIT=0 |
| Slap / Dance / Sigma / Money | PASS — 108 / 90 / 100 / 129 |
| Rivals / Dating / Girl discovery | PASS — 120 / 163 / 129 |
| Clone viz / Media / First clone | PASS — 162 / 146 / 131 |
| Late game / Final date / Content | PASS — 101 / 78 / 139 |
| Progression UI / GameHUD smoke | PASS — 126 / 14 |
| Main boot (`main.tscn`) | PASS — apartment boot EXIT=0 |
| Indep harness (buses/music/duck/money/camera/donor/M24) | PASS — `passed=45 failed=0` |
| Screenshots (QA opened each) | PASS with visual WARNINGs |
| No MODULE24 settings/persistence | PASS |
| No SCRIPT/Parse errors in suite logs | PASS |
| No runtime donor path | PASS |

---

## 2. Criteria

| Criterion | Status | Evidence | Reproduction |
|-----------|--------|----------|--------------|
| Buses Master/Music/SFX/UI/Ambience | PASS | `audio_director.log`, indep report | Headless audio + indep harness |
| Stage→music MANUAL/MEDIA/CLONE/FINAL | PASS | Audio self-test + indep; assets exist incl. `final_sparse.wav` | Same |
| Same-state travel no music restart | PASS | `music_start_count` unchanged | Indep + audio self-test |
| Duck restore | PASS | Music −8 → −12 → −8 dB | Indep + audio self-test |
| 100 money ticks → 0 unintended SFX | PASS | Oneshot pool/api = 0 after 100 `add_money` | Indep harness |
| CameraFeedback scale0 zero motion | PASS | Indep + `CAMERA_FB_TEST: ALL PASS (7)` | Indep + `tmp/m23_d` |
| No SCRIPT/Parse errors | PASS | Grep across `tmp/m23_qa/*.log` empty | Suite |
| No runtime donor path | PASS | AudioIds + `.import` scan | Indep |
| No MODULE24 settings menu/persistence | PASS | Forbidden paths absent; volume seams only | Indep + filesystem |
| MODULE 02–22 regression sample | PASS | All listed suites EXIT=0 ALL PASS | Headless suite |
| Asset licenses present | PASS | `docs/ASSET_LICENSES.md` lists music/SFX/ambience | Read |
| Screenshots match names | WARNING | See §4 — debug UI; final shot not beacon-like | Windowed indep |

### Edge cases exercised

1. Unknown sound/music id skipped safely (audio self-test warnings only; suite PASS).  
2. CameraFeedback scale=0 blocks rotation/shake/fov; slap null-safe when no player camera.

---

## 3. Commands executed

```powershell
$godot = "C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe"

# Headless M23 + MODULE sample (logs under tmp/m23_qa/*.log)
& $godot --path . --headless --quit-after 40000 res://audio/test/audio_director_self_test.tscn
& $godot --path . --headless --quit-after 20000 res://tmp/m23_d/camera_feedback_self_test.tscn
& $godot --path . --headless --quit-after 40000 res://minigames/slap/test/slap_minigame_test.tscn
& $godot --path . --headless --quit-after 40000 res://minigames/dance/test/dance_minigame_test.tscn
& $godot --path . --headless --quit-after 40000 res://minigames/sigma/test/sigma_minigame_test.tscn
& $godot --path . --headless --quit-after 40000 res://minigames/money/test/money_minigame_test.tscn
& $godot --path . --headless --quit-after 60000 res://game/rivals/test/rival_encounter_test.tscn
& $godot --path . --headless --quit-after 90000 res://game/dating/test/dating_test.tscn
& $godot --path . --headless --quit-after 40000 res://game/girls/test/girl_discovery_test.tscn
& $godot --path . --headless --quit-after 60000 res://game/clone_visualization/test/clone_visualization_test.tscn
& $godot --path . --headless --quit-after 60000 res://game/media/test/media_test.tscn
& $godot --path . --headless --quit-after 60000 res://game/first_clone/test/first_clone_test.tscn
& $godot --path . --headless --quit-after 60000 res://game/late_game/test/late_game_test.tscn
& $godot --path . --headless --quit-after 90000 res://game/final_date/test/final_date_test.tscn
& $godot --path . --headless --quit-after 40000 res://world/test/content_data_test.tscn
& $godot --path . --headless --quit-after 60000 res://ui/progression/test/progression_ui_self_test.tscn
& $godot --path . --headless --quit-after 40000 res://ui/hud/test/game_hud_smoke_test.tscn
& $godot --path . --headless --quit-after 3 res://main.tscn

# Indep harness
& $godot --path . --headless --quit-after 120000 res://tmp/m23_qa/m23_indep_qa.tscn
& $godot --path . --quit-after 0 res://tmp/m23_qa/m23_indep_qa.tscn
```

Godot CLI: `C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe`  
Note: `--quit-after` is **frames/iterations** (not seconds); windowed harness used `--quit-after 0` (disabled).

---

## 4. Screenshots — paths + factual content (QA opened each)

| File | Claimed | Actual content (opened) | Match |
|------|---------|-------------------------|-------|
| `tmp/m23_qa/01_apartment_hud.png` | Apartment + HUD | FPS view; HUD top-left `$ 0` / АВТОРИТЕТ / ОПЫТНОСТЬ / БАЛЛЫ; white `+` crosshair; very flat banded room (sky/grey/floor). Faint debug `mode=GAMEPLAY target=--`. | PASS location/HUD; WARNING debug text + sparse geometry |
| `tmp/m23_qa/02_lab.png` | Lab | Indoor FPS; tan floor/walls; teal door; HUD same four resources; crosshair. Harness asserted `laboratory`. Faint debug gameplay line. | PASS with WARNING debug overlay |
| `tmp/m23_qa/03_final_location_beacon.png` | Final location beacon | FPS; blue portal slab; prompt `[E] В город`; HUD; toast `Охват Земли: 25%`; debug `target=ToCity`. Harness asserted `final_location` id — **not** an obvious signal beacon. | WARNING — name vs visible content |

---

## 5. Engine logs

| Log | Path | Key line |
|-----|------|----------|
| AudioDirector | `tmp/m23_qa/audio_director.log` | `MODULE_23_AUDIO_TEST: ALL PASS (31)` EXIT=0 |
| CameraFeedback | `tmp/m23_qa/camera_feedback.log` | `CAMERA_FB_TEST: ALL PASS (7)` EXIT=0 |
| Slap / Dance / Sigma / Money | `tmp/m23_qa/{slap,dance,sigma,money}.log` | ALL PASS EXIT=0 |
| Rivals / Dating / Discovery | `tmp/m23_qa/{rivals,dating,girl_discovery}.log` | ALL PASS EXIT=0 |
| Clone viz / Media / First clone | `tmp/m23_qa/{clone_viz,media,first_clone}.log` | ALL PASS EXIT=0 |
| Late / Final / Content | `tmp/m23_qa/{late_game,final_date,content}.log` | ALL PASS EXIT=0 |
| Progression UI / HUD / Main | `tmp/m23_qa/{progression_ui,game_hud_smoke,main_boot}.log` | ALL PASS / boot EXIT=0 |
| Indep headless | `tmp/m23_qa/m23_indep_qa_headless.log` | `DONE passed=45 failed=0` |
| Indep windowed | `tmp/m23_qa/m23_indep_qa_windowed.log` | `DONE passed=45 failed=0` + PNG shots |
| Indep report | `tmp/m23_qa/m23_indep_qa_report.txt` | Full PASS list |
| Suite summary | `tmp/m23_qa/suite_summary.txt` | Per-log EXIT + ALL PASS |

Raw Godot stdout/stderr via Tee / `*>` redirect (not capture-journal-only).

Grep across `tmp/m23_qa/*.log`: **no** product `SCRIPT ERROR` / `Parse Error` / `Failed to load resource` / `date_factory_legacy`.

Expected intentional test warnings/errors (suite still PASS):

- AudioDirector missing-id warnings in audio self-test.
- Rival exhibition `got=2` push_error in rivals self-test path.
- Girl discovery invalid reaction push_error in API negative test.
- Engine RID/ObjectDB leak noise on quit (headless dummy + windowed Vulkan).

---

## 6. Blocking issues

None.

---

## 7. Non-blocking issues

1. **Debug overlay in gameplay shots** — faint `mode=GAMEPLAY target=…` visible in apartment/lab/final screenshots (presentation polish; not MODULE 23 audio failure).  
2. **`03_final_location_beacon.png` framing** — shows ToCity interactable + Earth-reach toast, not a clear final signal beacon; filename oversells content. Location id was `final_location` per PHP harness.  
3. **Apartment shot geometry** — extremely flat banded view; HUD readable but scene looks sparse from spawn look direction.  
4. **Pre-existing test push_errors** in rivals/girl_discovery self-tests (do not fail EXIT; unchanged by M23).  
5. **Exit RID/ObjectDB leaks** — engine cleanup noise on quit.

---

## 8. MODULE24 check

- No `settings_menu`, save manager, or settings persistence product files.  
- No `MODULE_24_*.md` implementation start.  
- AudioDirector volume setters + CameraFeedback scale seam present for later MODULE24 only.

---

## Overall status

**PASS** → **READY**

## Blocking issues

None.

## Non-blocking issues

See §7 (debug HUD text; final screenshot naming/framing; sparse apartment view; expected self-test push_errors; quit leaks).

## Evidence

`tmp/m23_qa/*.log`, `tmp/m23_qa/m23_indep_qa_report.txt`, `tmp/m23_qa/01_apartment_hud.png`, `02_lab.png`, `03_final_location_beacon.png`, `tmp/m23_qa/suite_summary.txt`, this report.

## Reproduction steps

1. Run headless commands in §3; confirm ALL PASS / EXIT=0.  
2. Run windowed indep: `Godot --path . --quit-after 0 res://tmp/m23_qa/m23_indep_qa.tscn`.  
3. Confirm `DONE passed=45 failed=0` and PNG sizes 1280×720.  
4. Open each PNG and verify HUD + location context (expect debug-text WARNING).  
5. Confirm no `ui/settings/*` or save persistence modules added.
