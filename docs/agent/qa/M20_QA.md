# M20_QA — MODULE 20 Independent QA

**Task:** M20_H_QA (recheck — WorldReachVisual reconnect)  
**Module:** 20 — Late Game Expansion  
**Date:** 2026-08-08  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  
**Evidence:** `tmp/m20_qa/`  
**DoD:** `docs/modules/MODULE_20_LATE_GAME_EXPANSION.md` + `docs/agent/ACCEPTANCE.md`

## Verdict

**PASS**

Previous blocking FAIL cleared: after `World.request_travel` into `production_area`, `WorldReachVisual` reconnects via `_enter_tree` → `_connect_signals` / `_refresh`. Live `add_reach` updates `Охват Земли: N` without re-enter (`visual_conn=true`, conns=7).

---

## Must re-prove (this recheck)

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| R1 | After real travel to `production_area`: visual connected to `world_reach_changed` | **PASS** | Indep log: `visual_conn=true`, `world_reach_changed_conns=7` (was 6 + false) — `tmp/m20_qa/m20_indep_qa_windowed.log` |
| R2 | `add_reach` / Reach XP updates `Охват Земли: N` without re-enter | **PASS** | After travel + modal cycle, `LateGameExpansion.add_reach(20)` → live label `Охват Земли: 20` with **no** manual `_refresh`. Shot `07_reach_display.png` |
| R3 | Headless MODULE_20 still PASS | **PASS** | `MODULE_20_TEST: ALL PASS (101)` EXIT=0 — `tmp/m20_qa/late_game_test.log` |
| R4 | Whole MODULE 20 DoD | **PASS** | All prior Must-verify rows green; indep harness `passed=112 failed=0` EXIT=0 |

Indep harness: **`M20_INDEP_QA: DONE passed=112 failed=0`** EXIT=0 (`tmp/m20_qa/m20_indep_qa_windowed.log`, `tmp/m20_qa/m20_indep_qa_report.txt`).

---

## Must verify (full MODULE 20)

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Headless late_game_test ALL PASS (~101) | **PASS** | `MODULE_20_TEST: ALL PASS (101)` EXIT=0 — `tmp/m20_qa/late_game_test.log` |
| 2 | MODULE 18 / 19 / 03 regressions green | **PASS** | Prior recheck evidence retained under `tmp/m20_qa/` (M18/M19/M03 ALL PASS). Recheck scope focused on reconnect + MODULE_20 headless. |
| 3 | F5 boots apartment | **PASS** | Indep shot `01_apartment_boot.png` + prior `f5_main_boot.log` |
| 4 | President anchors: clones=0 empty; clones≥1 + STAGE_5 spawn near ToProduction | **PASS** | Empty at clones=0; after `set_clone_counts(1,0,0)` girl+rival spawn; girl dist to ToProduction `2.86`. Shot `03_city_president_gate.png` |
| 5 | Discovery `STORY_PREREQUISITE` before first clone | **PASS** | `begin_attempt` / `discover_girl` rejected with `STORY_PREREQUISITE` at clones=0; cleared after clone |
| 6 | Assisted STAGE_6 → production_area → Global Terminal modal; Reach display; optional event | **PASS** | Terminal open/close/reopen; live Reach `0→20` via signal; customs +10 once / second reject. Shots `05`–`08` |
| 7 | Reach100 → FINALE + FINAL_DATE; final_location signal visible | **PASS** | Stage FINALE; FINAL_DATE unlocked; beacon wording. Shot `09_finale_signal.png` |
| 8 | No `girl_final_target` / no MODULE 21 final date gameplay | **PASS** | No `girl_final_target.tres`; no `game/finale` / `game/final_date`; no MODULE_21 spec; phone has no final-target id |
| 9 | Phone STAGE_5 President / STAGE_6 Reach / FINALE signal text | **PASS** | Shots `04`, `08`, `10` (AcceptDialog overlay noise noted below) |

---

## Player flow actually executed (recheck)

1. Headless `res://game/late_game/test/late_game_test.tscn` → ALL PASS (101), EXIT=0.
2. Confirmed product fix present: `world_reach_visual.gd` has `_enter_tree` → `_connect_signals()` + `_refresh()`, `_exit_tree` disconnect, `_signals_connected` guard (M19-style).
3. Windowed independent harness `res://tmp/m20_qa/m20_indep_qa.tscn`:
   - Real `request_travel(production_area)` at STAGE_6
   - Global Terminal open → close → reopen → control return
   - Mid-visit `add_reach(20)` **without leaving** → `visual_conn=true`, label `Охват Земли: 20`
   - City → production reenter still shows `20`
   - Customs once +10 → Reach 30; phone STAGE_6 text
   - Reach100 → FINALE + final_location beacon
   - Reset clears Reach; restore FINALE+100
4. Opened and described evidence screenshots (incl. new `05`/`07`).

---

## Edge cases

| Case | Status | Notes |
|------|--------|-------|
| clones=0 President anchors empty | **PASS** | Girl+rival child count 0 |
| Live spawn on first clone | **PASS** | Both anchors spawn near ToProduction |
| Despawn when clones cleared | **PASS** | Both clear; respawn on restore |
| Discovery bypass before clone | **PASS** | Hard `STORY_PREREQUISITE` |
| Terminal control return + reopen | **PASS** | Close → gameplay; reopen modal |
| Optional event once-only | **PASS** | Customs 20→30; second reject |
| ReachDisplay live mid-visit after travel | **PASS** | Signal connected; text updates to 20 without re-enter |
| ReachDisplay on re-enter | **PASS** | Shows `Охват Земли: 20` |
| Reset clears Reach | **PASS** | 100→0 on `reset_for_new_game` |

---

## Blocking issues

None.

---

## Non-blocking issues

| Issue | Notes |
|-------|--------|
| AcceptDialog overload text on some phone shots | Pre-existing «Проблема не в графике…» overlay; story lines still readable |
| Shot `07` side placeholder still `Охват Земли: 0` | Hardcoded scene Label3D placeholders (visibility-only); main `ReachDisplay` correctly shows `20` |
| HUD debug `mode=GAMEPLAY` / `mode=MODAL_UI` | Pre-existing debug HUD |
| Headless/windowed RID leaks at exit | Engine cleanup noise; suite EXIT=0 |
| Player `Trying to cast a freed object` during travel | Transient script error on interact target during location swap; flow continued |

---

## Screenshot descriptions (opened and inspected)

Evidence: `tmp/m20_qa/`

### 1) `01_apartment_boot.png`

- Low-poly apartment; Neighbor present; boot location apartment.
- Matches F5-equivalent apartment boot.

### 2) `02_city_president_empty_clones0.png`

- City hub; ToProduction / production gate; no President pair at clones=0.

### 3) `03_city_president_gate.png`

- After assisted first clone: female NPC near production gate; `[E] Познакомиться`.
- Matches President gate spawn.

### 4) `04_phone_stage5_president.png`

- Phone: STAGE_5 / Президент; AcceptDialog overlay noise; story lines confirm President stage.

### 5) `05_production_terminal.png` (recheck)

- Production area after STAGE_6 travel: teal Global Terminal pedestal, map board, **«ГЛОБАЛЬНЫЙ ТЕРМИНАЛ»**.
- Main Reach label **«Охват Земли: 0»** at enter (reach still 0).
- Side placeholder also `Охват Земли: 0`; prompt `[E] В город`; `mode=GAMEPLAY`.
- Matches pre-`add_reach` production terminal state.

### 6) `06_global_terminal_modal.png`

- Modal **«ГЛОБАЛЬНОЕ РАСШИРЕНИЕ»** with Reach / clone assignment / rates.

### 7) `07_reach_display.png` (recheck — critical)

- Mid-visit after `add_reach(20)` **without re-enter**: main board label **«Охват Земли: 20»**.
- Side placeholder still shows stale **«Охват Земли: 0»** (non-blocking hardcoded placeholder).
- Confirms live signal path; no manual `_refresh` needed (harness logged live text before any refresh branch).

### 8) `08_phone_stage6_reach.png`

- Phone: STAGE_6 / Мировое расширение / Охват Земли: 30 / 100.

### 9) `09_finale_signal.png`

- final_location: **«ФИНАЛ»**; beacon / romantic status unset; no final-date gameplay.

### 10) `10_phone_finale_signal.png`

- Phone FINALE texts; no `girl_final_target` id.

---

## Overall status

**PASS**

## Blocking issues

None.

## Non-blocking issues

- AcceptDialog overlay on phone captures.
- Placeholder Label3D texts not rewritten on Reach change (main ReachDisplay OK).
- Debug HUD; exit RID leaks; transient freed-object cast on travel.

## Evidence

- `tmp/m20_qa/late_game_test.log` — MODULE_20 ALL PASS (101), EXIT=0
- `tmp/m20_qa/m20_indep_qa_windowed.log` — indep PASS 112/0, EXIT=0; live reconnect proof
- `tmp/m20_qa/m20_indep_qa_report.txt`
- `tmp/m20_qa/01_apartment_boot.png` … `10_phone_finale_signal.png` (regenerated this recheck)
- Prior regression logs retained: `module_18_clone_incremental.log`, `module_19_clone_visualization.log`, `module_03_content.log`, `f5_main_boot.log`
- Harness: `tmp/m20_qa/m20_indep_qa.tscn` (+ `.gd`)
- Fix under test (product, not edited by QA): `game/late_game/world_reach_visual.gd` `_enter_tree` reconnect

## Reproduction steps

1. Headless:  
   `Godot --headless --path <repo> res://game/late_game/test/late_game_test.tscn` → ALL PASS (101), EXIT=0.
2. Windowed:  
   `Godot --path <repo> res://tmp/m20_qa/m20_indep_qa.tscn` → `passed=112 failed=0`, EXIT=0.
3. Critical log line:  
   `ReachDisplay after add_reach live text='Охват Земли: 20' visual=true world_reach_changed_conns=7 visual_conn=true`
4. Shots `05` (reach 0 at enter) → `07` (reach 20 mid-visit, no re-enter).
