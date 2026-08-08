# M21_QA — MODULE 21 Independent QA

**Task:** M21_F_QA  
**Module:** 21 — Final Date Sequence  
**Date:** 2026-08-08  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  
**Evidence:** `tmp/m21_qa/`  
**DoD:** `docs/modules/MODULE_21_FINAL_DATE_SEQUENCE.md` + `docs/agent/ACCEPTANCE.md`

## Verdict

**PASS** → recommend **READY**

Independent headless + windowed evidence shows Final Date Sequence works on a real `final_location` path: signal entry → INTRO → DANCE/SLAP exhibitions without Authority/`mark_rival_defeated` → success ending + Continue with world still playable; fail → no permanent penalty → full retry. Phone FINALE signal / completed + `Последняя: +5` verified visually. Regressions MODULE 03 / 06 / 20 green; MODULE 21 self-test **ALL PASS (78)**.

---

## 1. Summary

| Area | Result |
|------|--------|
| Main boot (`main.tscn`) | PASS — apartment boot, no SCRIPT/Parse errors |
| `final_date_test.tscn` | PASS — `ALL PASS (78)` |
| `content_data_test.tscn` | PASS — `ALL PASS (139)` |
| `rival_encounter_test.tscn` | PASS — `ALL PASS (120)` |
| `late_game_test.tscn` | PASS — `ALL PASS (101)` |
| Indep windowed harness | PASS — `passed=101 failed=0` |
| Screenshots (opened by QA) | PASS with one framing WARNING on `02_final_signal.png` |

---

## 2. Commands executed

```powershell
# Headless MODULE 21
& "...\Godot_v4.7.1-stable_win64_console.exe" --path . --headless --quit-after 90000 res://game/final_date/test/final_date_test.tscn
# → tmp/m21_qa/final_date_test.log

# Regressions
& "...\Godot_v4.7.1-stable_win64_console.exe" --path . --headless --quit-after 40000 res://world/test/content_data_test.tscn
# → tmp/m21_qa/content_data_test.log

& "...\Godot_v4.7.1-stable_win64_console.exe" --path . --headless --quit-after 50000 res://game/rivals/test/rival_encounter_test.tscn
# → tmp/m21_qa/rival_encounter_test.log

& "...\Godot_v4.7.1-stable_win64_console.exe" --path . --headless --quit-after 60000 res://game/late_game/test/late_game_test.tscn
# → tmp/m21_qa/late_game_test.log

# Main boot smoke (quit-after is seconds)
& "...\Godot_v4.7.1-stable_win64_console.exe" --path . --headless --quit-after 3 res://main.tscn
# → tmp/m21_qa/main_boot.log

# Independent windowed player-path harness (QA-only under tmp/)
& "...\Godot_v4.7.1-stable_win64_console.exe" --path . --quit-after 120 res://tmp/m21_qa/m21_indep_qa.tscn
# → tmp/m21_qa/m21_indep_qa_windowed.log + PNGs + m21_indep_qa_report.txt
```

Godot CLI: `C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe`

---

## 3. Engine logs paths

| Log | Path | Key line |
|-----|------|----------|
| MODULE 21 self-test | `tmp/m21_qa/final_date_test.log` | `MODULE_21_TEST: ALL PASS (78)` EXIT=0 |
| Content / MODULE 03 | `tmp/m21_qa/content_data_test.log` | `MODULE_03_TEST: ALL PASS (139)` EXIT=0 |
| Rivals / MODULE 06 | `tmp/m21_qa/rival_encounter_test.log` | `MODULE_06_TEST: ALL PASS (120)` EXIT=0 |
| Late game / MODULE 20 | `tmp/m21_qa/late_game_test.log` | `MODULE_20_TEST: ALL PASS (101)` EXIT=0 |
| Main boot | `tmp/m21_qa/main_boot.log` | Boot → apartment; Player ready; no SCRIPT ERROR |
| Indep windowed | `tmp/m21_qa/m21_indep_qa_windowed.log` | `DONE passed=101 failed=0` EXIT=0 |
| Indep report | `tmp/m21_qa/m21_indep_qa_report.txt` | Full PASS list |

Raw Godot stdout/stderr captured via Tee (not capture-journal-only). Expected intentional test `push_error` lines appear in MODULE 03/06 (missing fixture / unsupported exhibition type). Exit RID/ObjectDB leak warnings present on all Godot exits — engine cleanup noise, not gameplay script errors. Grep across `tmp/m21_qa/*.log`: **no** `SCRIPT ERROR` / `Parse Error` / `Failed to load resource`.

---

## 4. Screenshots — paths + factual content (QA opened each)

| File | What it actually shows |
|------|------------------------|
| `tmp/m21_qa/01_apartment_boot.png` | Apartment («КВАРТИРА»): neighbor NPC (blonde / white top / orange pants), date table + self-esteem labels, blue door, crosshair, `mode=GAMEPLAY`. Matches boot location. |
| `tmp/m21_qa/02_final_signal.png` | `final_location` signal chamber: beacon «ФИНАЛ», «ИСТОЧНИК СИГНАЛА: ЗА ПРЕДЕЛАМИ ЗЕМЛИ», «РОМАНТИЧЕСКИЙ СТАТУС: НЕ УСТАНОВЛЕН», stylized blue pad/walls. **WARNING:** on-screen E prompt is `[E] В город` (`mode=GAMEPLAY target=ToCity`) — framing near ToCity transition; signal interactability verified separately in harness (`can_interact` + prompt `[E] Ответить на внеземной сигнал`). |
| `tmp/m21_qa/03_phone_finale_signal.png` | Phone journal FINALE: «Внеземной сигнал обнаружен», earth exhausted, romantic target outside Earth, final location opened. No raw `girl_final_target` id. |
| `tmp/m21_qa/04_mid_date_target.png` | Final date INTRO modal: title «Последняя», «Сигнал принят», dialogue line from Последняя, «Далее»; blonde target actor visible behind UI in final_location. |
| `tmp/m21_qa/05_phone_finale_complete.png` | Phone after success: «ФИНАЛ ЗАВЕРШЁН», «Последняя: +5», Охват Земли 100, Опытность 1 / Баллы прокачки 1. |

---

## 5. Player flow verified

### Happy path (assisted FINALE seed → real World travel)

1. Boot / reset → apartment (`01_apartment_boot.png`).
2. Edge: STAGE_6 + reach 50 → `final_location` travel rejected.
3. Seed: `GameStage.FINALE`, `StoryFeature.FINAL_DATE`, `world_reach=100`, chars L2, not conquered.
4. Travel `final_location` → `FinalSignalInteractable` present + `can_interact` + prompt «Ответить на внеземной сигнал» (`02` beacon visual).
5. Phone FINALE signal text (`03`).
6. Start via `FinalSignalInteractable._on_interact` → INTRO, target actor spawned, **no DatingCore session** (`04`).
7. Events + exhibition rivals: DANCE (`rival_final_ceremonial`) then SLAP (`rival_final_gravity`) with `set_test_auto_win_exhibition(true)`; Authority unchanged; rivals **not** `mark_rival_defeated`.
8. Success: relationship 5, conquered, XP+1 / UP+1 once; SUCCESS → ending → Continue; stage stays FINALE; post-ending travel city_hub then return final_location; signal locked («Финал завершён»).
9. Phone completed: «ФИНАЛ ЗАВЕРШЁН» + «Последняя: +5» (`05`).

### Fail path (edge)

1. Restart FINALE-ready; start date; force PLAYER_LOSS on rival1 minigame.
2. FAILURE / RIVAL_LOSS; money / authority / XP / UP / reach / relationship unchanged; not conquered; no rival defeat.
3. Retry → INTRO + score 0; abort → gameplay; `can_start_final_date` true again.

### Restore / lock edge

1. Conquered → reset clears → restore FINALE + conquered flags → `can_start_final_date` false.

### Headless contracts

| Suite | Status |
|-------|--------|
| MODULE 21 final_date 78 | PASS |
| MODULE 03 content 139 | PASS |
| MODULE 06 rivals 120 | PASS |
| MODULE 20 late_game 101 | PASS |

---

## 6. Criteria table

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | F5 / main boot no script errors | **PASS** | `main_boot.log`: apartment boot + Player ready; no SCRIPT/Parse errors |
| 2 | Preconditions FINALE / FINAL_DATE / reach≥100 / not conquered | **PASS** | Indep report lines stage FINALE, FINAL_DATE, reach, not conquered |
| 3 | Enter final_location; FinalSignalInteractable when ready | **PASS** | Travel SUCCESS; can_interact + prompt; beacon shot `02` |
| 4 | Start → INTRO → checkpoints → DANCE then SLAP without Authority / mark_rival_defeated | **PASS** | Indep: rival1/2 won; authority unchanged; rivals not defeated; controller source has no `mark_rival_defeated` |
| 5 | Success: rel 5 + conquered + XP once; ending + Continue; world playable; stage FINALE | **PASS** | Indep + phone `05` (XP1/UP1); city_hub travel after ending |
| 6 | Fail: comedy, no permanent penalty, full retry | **PASS** | FAILURE phase; metrics unchanged; retry INTRO |
| 7 | Phone FINALE signal / Последняя / +5 | **PASS** | Shots `03` and `05` |
| 8 | Headless final_date 78 + content + rivals + late_game | **PASS** | Logs listed above |
| 9 | Content: girl_final_target + 2 exhibition rivals; no ordinary dating pools | **PASS** | ContentDB + empty `dating_pool_ids` |
| 10 | MODULE 02–20 regressions (practical sample) | **PASS** | 03/06/20 + main; not every MODULE 02–19 suite re-run |

---

## 7. Limitations

- FINALE reached by assisted `restore_stage` / `set_world_reach`, not organic STAGE_1→Reach100 grind.
- Exhibition wins forced via `set_test_auto_win_exhibition(true)` / forced loss emit — not human minigame play.
- Full disk save-file round-trip not exercised (`GameState.export_save_dict` unavailable); persistence checked via reset + restore APIs.
- `02_final_signal.png` frames ToCity prompt; signal prompt proven in logic, not that PNG overlay.
- Debug `mode=` HUD visible on shots (project-wide).
- Godot exit RID/ObjectDB leaks on all runs (noise).
- MODULE 02–19 full matrix not re-executed beyond sampled suites.

---

## 8. Unmet criteria

None blocking relative to ACCEPTANCE / MODULE 21 player-visible DoD.

Non-blocking / WARNING only:

1. Screenshot `02` naming vs on-screen E prompt (ToCity vs signal).
2. No organic end-to-end F5→FINALE→signal without assisted seed.
3. No full user:// save file load cycle.

---

## 9. Blocking / non-blocking

### Blocking issues

None.

### Non-blocking issues

| Issue | Severity |
|-------|----------|
| `02_final_signal.png` shows ToCity interact prompt while beacon is correct | WARNING |
| Debug mode HUD on screenshots | WARNING (existing) |
| Exit-time RID/ObjectDB leaks | WARNING (engine cleanup) |
| Full file save/load not proven for FINALE conquest | WARNING |
| Organic long-campaign path to FINALE not re-played | WARNING |

---

## 10. Reproduction steps

1. Run headless suites listed in §2; confirm ALL PASS lines in `tmp/m21_qa/*_test.log`.
2. Run windowed: `res://tmp/m21_qa/m21_indep_qa.tscn` (creates PNGs + report).
3. Open PNGs under `tmp/m21_qa/` and confirm apartment / final beacon / phone FINALE / INTRO Последняя / phone completed +5.
4. Optional manual: F5 → (debug) seed FINALE + reach 100 → travel final_location → E on signal → walk date → exhibitions → ending Continue.

---

## 11. PASS/FAIL recommendation

**PASS**

Orchestrator ACCEPTANCE mapping: **READY**

Do not start MODULE 22 from this QA report alone — Orchestrator milestone update remains separate.
