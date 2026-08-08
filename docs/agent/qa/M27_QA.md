# M27 QA — MODULE 27 Full Game QA (light smoke + RC recheck)

**Task id:** M27  
**Date:** 2026-08-08  
**QA role:** Independent `df-qa-worker` (no product-code changes)  
**Repo:** `C:\Users\User\Documents\GodotProjects\date_factory`  
**Godot CLI:** `C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe`  
**GodotIQ:** connected (editor play for title smoke)  
**HEAD:** `1f5b8dd`  
**Specs:** `docs/modules/MODULE_27_FULL_GAME_QA.md` · `docs/agent/ACCEPTANCE.md`

---

## Overall status

**READY** (automated / scripted RC gate)

- `required_for_rc`: **33/33 PASS**
- BLOCKER / MAJOR: **0 / 0**
- Manual A–F: **NOT EXECUTABLE IN ENVIRONMENT** (honest; not claimed)
- Light title → New Game → return-to-title API: **PASS** with one visual evidence WARNING

Orchestrator may accept READY for RC on automated evidence. Do not treat Manual A–F as done.

---

## Criteria

| # | Criterion | Status | Evidence | Reproduction |
|---|---|---|---|---|
| 1 | All `required_for_rc` suites PASS | **PASS** | `tmp/qa/summary.txt` TOTAL 33 / PASS 33 / FAIL 0; `tmp/qa/runner_rc_smoke.out` | `py -3 tools/qa/run_all_tests.py --only-rc` |
| 2 | `world_location` completes | **PASS** | `MODULE_12_TEST: ALL PASS (127)` | same runner |
| 3 | 14A / 14B catalog asserts | **PASS** | 14A ALL PASS (121); 14B ALL PASS (85) | same |
| 4 | Scripted Route A/B/save | **PASS** | `MODULE_27_FULL_GAME: ALL PASS (157)` | `full_game_integration` |
| 5 | ContentDB / schema v1 | **PASS** | content_data ALL PASS; `SAVE_SCHEMA_VERSION = 1` | content_data + `persistence/save_types.gd` |
| 6 | BLOCKER=0 MAJOR=0 | **PASS** | `docs/qa/KNOWN_ISSUES.md` | — |
| 7 | No MODULE28 features | **PASS** | Scope QA/docs/evidence only this session | — |
| 8 | Title / New Game smoke | **PASS** | GodotIQ play main; screenshots under `tmp/qa/manual_smoke/` | §Reproduction · smoke |
| 9 | `SaveSystem.return_to_title` | **PASS** | API `ok=true`; buttons visible_in_tree | §Reproduction · smoke |
| 10 | Visual return-to-title PNG matches name | **WARNING** | `03_return_to_title.png` content = apartment view; use `03b_title_after_replay.png` for title chrome | Open images |
| 11 | Manual routes A–F | **NOT EXECUTABLE** | No full F5 multi-hour routes in this environment | — |

### Edge cases

| Edge | Status | Notes |
|---|---|---|
| Sync `start_new_game` via GodotIQ exec | **WARNING** | Often times out; deferred `call_deferred("start_new_game")` succeeds |
| Post-suite SIGSEGV (save / integration / world_save_pose) | **WARNING** | KI-M27-01; ALL PASS precedes crash |
| Title UI hide required for apartment shot | **PASS** | SaveSystem alone does not hide title; `hide_menu` / `_enter_gameplay` needed |
| Apartment spawn visual | **PASS** (functional) | 3D room + blonde NPC; geometry from this spawn looks sparse/greybox — not a route blocker for smoke |

---

## Blocking issues

None.

---

## Non-blocking issues

1. **KI-M27-01** — Headless SIGSEGV after ALL PASS on some suites (exit `3221225477`).
2. **Return-to-title screenshot mismatch** — `03_return_to_title.png` still shows apartment FPS; API/title button visibility confirmed separately; `03b_title_after_replay.png` shows title after clean replay.
3. **GodotIQ sync New Game hang** — prefer deferred boot for agent smoke; player UI path not fully clicked through (click timed out once).
4. **Manual A–F** — still not run; remaining human/manual count = **6** routes.

---

## Evidence

| Path | Notes |
|---|---|
| `tmp/qa/summary.txt` | 33/33 PASS |
| `tmp/qa/runner_rc_smoke.out` | Full runner transcript |
| `tmp/qa/*.log` | Per-suite engine logs |
| `tmp/qa/manual_smoke/01_title.png` | Title menu (DATE FACTORY / Новая игра) — verified |
| `tmp/qa/manual_smoke/02_apartment_after_new_game.png` | Apartment/gameplay 3D + NPC — verified |
| `tmp/qa/manual_smoke/03_return_to_title.png` | **Misnamed content** (apartment); do not treat as title |
| `tmp/qa/manual_smoke/03b_title_after_replay.png` | Title after clean GodotIQ replay |
| `tmp/m27_qa/` | Copies of smoke shots + summary + runner out |
| `docs/qa/FULL_GAME_QA_REPORT.md` | Updated final status |
| `docs/qa/REGRESSION_MATRIX.md` | Updated 33/33 |
| `docs/qa/KNOWN_ISSUES.md` | KI-M27-02 closed |

### Screenshot content (opened and described)

1. **01_title.png** — Dark two-tone backdrop; centered panel; “DATE FACTORY”; “Главное меню”; buttons Продолжить / Новая игра / Загрузить / Настройки / Выход. Matches title.
2. **02_apartment_after_new_game.png** — First-person / near-eye view of compact interior: grey walls, blue floor/ceiling, blue doorway, box props, blonde NPC in white top / brown pants. Matches gameplay location after New Game (`loc=apartment`).
3. **03_return_to_title.png** — Same apartment geometry as (2), **not** title UI. Filename does not match content.
4. **03b_title_after_replay.png** — Title menu again after stop/play (not the same continuous in-session return frame).

---

## Reproduction steps

### Automated RC

```powershell
cd C:\Users\User\Documents\GodotProjects\date_factory
py -3 tools/qa/run_all_tests.py --only-rc
# Expect: TOTAL 33 / PASS 33 / FAIL 0
# Some suites may print ALL PASS then exit=3221225477 (KI-M27-01)
```

### Light title smoke (GodotIQ)

1. `godotiq_run` action=play scene=main → title visible.
2. Capture / save `01_title.png`.
3. `SaveSystem.call_deferred("start_new_game")` (sync call often times out from exec).
4. Call title `hide_menu` (or equivalent) + optional `player.enter_gameplay`.
5. Confirm `World.current_location_id == "apartment"`; save `02_apartment_after_new_game.png`.
6. `SaveSystem.return_to_title()` → expect `ok`; `show_menu` → title buttons visible_in_tree.
7. Prefer a fresh play capture for title chrome if viewport PNG after show_menu still shows 3D.

---

## Recommendation

| Gate | Verdict |
|---|---|
| Automated `required_for_rc` | **PASS → READY** |
| Scripted integration A/B/save | **PASS** |
| Light title / New Game / return API | **PASS** (visual return PNG WARNING) |
| Manual A–F | **NOT EXECUTABLE** — do not claim READY for human multi-route playtest completion |
| MODULE28 | **None** |

**Final independent recommendation for Orchestrator:** **READY** for MODULE 27 RC on automated + scripted evidence, with Manual A–F explicitly remaining out of environment.
