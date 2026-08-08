# M19_QA — MODULE 19 Independent QA (recheck)

**Task:** M19_D_QA  
**Module:** 19 — Physical Clone Visualization  
**Date:** 2026-08-08  
**Agent:** df-qa-worker  
**Recheck focus:** critical blockers only (signal reconnect after World.travel; FirstClone duplicate representative)  
**Product code changes by QA:** none  
**Evidence:** `tmp/m19_qa/`  
**DoD:** `docs/modules/MODULE_19_PHYSICAL_CLONE_VISUALIZATION.md`

## Verdict

**PASS**

Previous critical FAILs are cleared after Orchestrator fixes (`CloneVisualizationController._enter_tree` reconnect + refresh; `FirstClone._place_assigned_actor` clears when controller owns lab).

---

## Must re-prove (critical)

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | MODULE_19 / 17 / 18 headless PASS | **PASS** | M19 `ALL PASS (158)` EXIT=0 — `tmp/m19_qa/clone_visualization_self_test.log`. M17 `ALL PASS (121)` EXIT=0 — `tmp/m19_qa/first_clone_self_test.log`. M18 `ALL PASS (110)` EXIT=0 — `tmp/m19_qa/clone_incremental_self_test.log`. |
| 2 | After real `World` travel to laboratory: `_signals_connected==true` OR live counts refresh rooms | **PASS** | Indep log: `controller _signals_connected=true clone_counts_changed_conn=true conn_count=5`. Checks: `controller _signals_connected true after lab load`, `controller listed on GameState.clone_counts_changed`. |
| 3 | Live CloneIncremental assign/unassign dating/work refreshes authored rooms without reload | **PASS** | Signal-only path (no manual refresh): dating viz 3→4 on `assign_one_to_dating`; work viz→3 on `assign_one_to_work`; dating viz→3 on `unassign_one_from_dating`; slot04 opens/closes with counts. |
| 4 | After FirstClone `assign_work` in lab with controller: no FirstCloneRepresentative / `get_representative_actor()==null` while viz present | **PASS** | `FirstClone rep after assign_work valid=false`; `no FirstCloneRepresentative nodes in tree`; `viz work present while FirstClone suppressed post-assign`; still null while dating=1 / work=3 / free=2. |
| 5 | Screenshots of active rooms + external overflow; opened and described | **PASS** | Shots `02`–`04` opened below; phone aggregate `05` also captured. |

---

## Full criteria matrix

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Headless MODULE_19_TEST ALL PASS (~158) | **PASS** | `MODULE_19_TEST: ALL PASS (158)` EXIT=0 |
| 2 | MODULE_17 + MODULE_18 still PASS | **PASS** | 121 / 110 ALL PASS, EXIT=0 |
| 3 | F5 boots apartment | **PASS** | Main `--quit-after 8`: `[DF][MODULE_12] Boot -> apartment via World`, Player ready. Shot `01_apartment_boot.png`. |
| 4 | Assisted STAGE_5 + clones: authored rooms; dating 1/5/10; work/free; external label | **PASS** | Markers present; dating1/5/10 slots; work=3 free=2; external total=25 label `ВНЕШНИЙ ПОТОК: 25`. |
| 5 | Live reassignment refreshes viz without reload | **PASS** | Was FAIL; now signal path works after travel. |
| 6 | Actor count capped at high totals | **PASS** | dating=100 / total=10000 → `count_presentation_character_actors()=25` (≤27). |
| 7 | FirstClone no duplicate representative in lab with controller | **PASS** | Was FAIL; now suppressed immediately after `assign_work`. |
| 8 | No President / no MODULE 20 | **PASS** | No president content; stage STAGE_5; phone has no President text. |
| 9 | Screenshots opened/described | **PASS** | All five PNGs opened and described below. |
| 10 | Write `docs/agent/qa/M19_QA.md` | **PASS** | This file. |

Indep harness summary: **`M19_INDEP_QA: DONE passed=118 failed=0`** EXIT=0 (`tmp/m19_qa/m19_indep_qa_windowed.log`, `tmp/m19_qa/m19_indep_qa_report.txt`).

---

## Player flow actually executed

1. Headless MODULE_19_TEST ALL PASS (158).
2. Headless MODULE_17_TEST ALL PASS (121).
3. Headless MODULE_18_TEST ALL PASS (110).
4. Main-scene F5 smoke: boots apartment via World (`--quit-after 8`).
5. Independent live harness `tmp/m19_qa/m19_indep_qa.tscn` (**118 PASS / 0 FAIL**, windowed):
   - World boot apartment + Neighbor
   - **ASSISTED** `restore_stage(STAGE_5)` + scientist conquered → `World.request_travel` laboratory
   - After travel: `_signals_connected=true`, controller on `clone_counts_changed`
   - FirstClone calibration → `assign_work` → **no** FirstCloneRepresentative; viz work≥1
   - Dating 1/5/10, work/free caps, external label 25
   - Live `CloneIncremental.assign_one_to_*` / unassign refreshes viz without reload
   - Actor budget 25 at dating=100 and total=10000
   - Phone КЛОНЫ aggregate-only; no President; no MODULE 20
   - City→lab re-enter reconstructs dating visuals; FirstClone stays suppressed
6. Opened and described evidence screenshots.

---

## Edge cases

| Case | Status | Notes |
|------|--------|-------|
| Live assign without reload | **PASS** | GS dating 3→4; viz dating 3→4; slot04 opens. |
| Live unassign without reload | **PASS** | dating viz tracks to 3; slot04 closes. |
| Live assign work without reload | **PASS** | work viz→3 matches GS. |
| Lab reload / re-travel | **PASS** | New instance reconstructs dating visuals from aggregate. |
| FirstClone suppress on first assign | **PASS** | `get_representative_actor()==null` immediately; no named reps. |
| FirstClone suppress while viz work/free/dating present | **PASS** | Still null at dating1/work3/free2. |
| Huge aggregate actor budget | **PASS** | ≤27 at 100 dating and 10000 total. |
| Phone aggregate-only | **PASS** | Counts/rates only; no per-clone IDs / room UI. |

---

## Blocking issues

None.

---

## Non-blocking issues

| Issue | Notes |
|-------|--------|
| External flow screenshot clarity | Shot `04_external_flow.png` shows area signs `ВНЕШНИЕ ПЛОЩАДКИ` / `внешний поток:`; numeric `ВНЕШНИЙ ПОТОК: 25` confirmed programmatically but not clearly readable in this camera frame (pillar occludes). |
| HUD debug `mode=GAMEPLAY` / `mode=MODAL_UI` | Present on FPS/UI shots (pre-existing debug HUD, not MODULE 19-specific). |
| Headless/windowed RID/instance leaks at exit | Engine cleanup noise on quit; EXIT=0 for all module suites and indep harness. |

---

## Screenshot descriptions (opened and inspected)

Evidence: `tmp/m19_qa/`

### 1) `01_apartment_boot.png`

- Low-poly apartment; large label **«КВАРТИРА»**.
- Neighbor CharacterActor (blonde, white tee, orange pants) near blue door.
- Dating table «Стол для свидания»; «Самооценка» pillar; crosshair; HUD `mode=GAMEPLAY`.
- Matches F5 apartment boot.

### 2) `02_lab_overview_rooms.png`

- Laboratory observation corridor; labels **«ЛАБОРАТОРИЯ»**, **«КОРИДОР НАБЛЮДЕНИЯ»**, **«КАЛИБРОВКА»**.
- Authored glass dating rooms visible (e.g. **«КОМНАТА 04»** and neighboring room labels).
- Two free-clone presentation actors on purple pads in corridor center.
- Matches “lab overview with rooms”.

### 3) `03_active_dating_room_label.png`

- Close-up into an active dating cubicle through glass.
- Floating status **«КЛОН ОБЪЯСНЯЕТ СВОЮ СИСТЕМУ»** (matches harness `active dating room label`).
- Anonymous female presentation actor inside; clone figure partially visible behind pillar.
- Matches “active dating room label”.

### 4) `04_external_flow.png`

- Mass/external wing corner; signs **«ВНЕШНИЕ ПЛОЩАДКИ»** and **«внешний поток:»**.
- Minimal geometry + dark pillar; HUD `mode=GAMEPLAY`; player hand/arm at bottom.
- Programmatic controller label at capture time: `ВНЕШНИЙ ПОТОК: 25` (number not clearly readable in this frame).

### 5) `05_phone_aggregate.png`

- Phone modal «Телефон — Журнал»; `mode=MODAL_UI`.
- Story: **СТАДИЯ 5 / Лаборатория** — «Автоматизация запущена. Наращивай производство клонов.»
- **КЛОНЫ** aggregate only: Всего 40; Свободно 15; Работают 8; Денег/мин 160; На свиданиях 17; Свиданий/мин 8.5.
- No President; no per-clone list.

---

## Commands + key log lines

### Headless MODULE 19

```text
Godot_v4.7.1-stable_win64_console.exe --headless --path <repo> res://game/clone_visualization/test/clone_visualization_test.tscn
→ MODULE_19_TEST: ALL PASS (158) EXIT=0
```

### Headless MODULE 17 / 18

```text
... res://game/first_clone/test/first_clone_test.tscn
→ MODULE_17_TEST: ALL PASS (121) EXIT=0

... res://game/clone_incremental/test/clone_incremental_test.tscn
→ MODULE_18_TEST: ALL PASS (110) EXIT=0
```

### F5 apartment boot

```text
... --path <repo> --quit-after 8
→ [DF][MODULE_12] Boot -> apartment via World
→ [DF][MODULE_01] Player ready
→ EXIT=0
```

### Independent live harness (recheck)

```text
... --path <repo> res://tmp/m19_qa/m19_indep_qa.tscn
→ controller _signals_connected=true clone_counts_changed_conn=true conn_count=5
→ FirstClone rep after assign_work valid=false parent=
→ live assign dating viz before=3 after=4 gs=4
→ live assign work viz=3 gs=3
→ live unassign dating viz=3 gs=3
→ M19_INDEP_QA: DONE passed=118 failed=0
→ EXIT=0
```

---

## Overall status

**PASS**

## Blocking issues

None.

## Non-blocking issues

1. External numeric label poorly visible in shot `04` camera frame (programmatic `ВНЕШНИЙ ПОТОК: 25` OK).
2. Pre-existing gameplay HUD `mode=` debug text on screenshots.
3. Engine RID/object leak noise on process exit (does not affect EXIT=0).

## Evidence

- `tmp/m19_qa/clone_visualization_self_test.log`
- `tmp/m19_qa/first_clone_self_test.log`
- `tmp/m19_qa/clone_incremental_self_test.log`
- `tmp/m19_qa/f5_main_boot.log`
- `tmp/m19_qa/m19_indep_qa_windowed.log`
- `tmp/m19_qa/m19_indep_qa_report.txt`
- `tmp/m19_qa/m19_indep_qa.gd` / `m19_indep_qa.tscn` (QA-only harness)
- `tmp/m19_qa/01_apartment_boot.png`
- `tmp/m19_qa/02_lab_overview_rooms.png`
- `tmp/m19_qa/03_active_dating_room_label.png`
- `tmp/m19_qa/04_external_flow.png`
- `tmp/m19_qa/05_phone_aggregate.png`
- `docs/agent/qa/M19_QA.md` (this report)

## Reproduction steps

1. Headless MODULE 19/17/18 suites (all PASS).
2. `Godot --path <repo> --quit-after 8` → apartment boot.
3. Windowed: `Godot --path <repo> res://tmp/m19_qa/m19_indep_qa.tscn`
4. Confirm: `_signals_connected=true`, live dating/work assign/unassign updates viz, FirstClone rep null after `assign_work`, `passed=118 failed=0`.
5. Open PNGs under `tmp/m19_qa/` and compare to descriptions above.
