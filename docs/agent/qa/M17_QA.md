# M17_QA — MODULE 17 Independent QA

**Task:** M17_QA  
**Module:** 17 — First Clone Sequence  
**Date:** 2026-08-08  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  
**Evidence:** `tmp/m17_qa/`

## Verdict

**PASS**

Post-integration fix (Orchestrator): MODULE_15 / MODULE_14B boundary asserts updated for Scientist present in catalog (LABORATORY still locked at Media stage). Full suite 03–17 green after that.

---

## Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | `MODULE_17_TEST` ALL PASS | **PASS** | Headless `res://game/first_clone/test/first_clone_test.tscn` → `MODULE_17_TEST: ALL PASS (96)` EXIT=0. Log: `tmp/m17_qa/first_clone_self_test.log`. |
| 2 | F5 apartment boots | **PASS** | Main scene `--quit-after 8`: `[DF][MODULE_12] Boot -> apartment via World`, FirstClone ready, Player ready. Indep: `reset_to_start` → `apartment`, Neighbor present. Shot `01_apartment_boot.png`. Log: `tmp/m17_qa/f5_main_boot.log`. |
| 3 | After recognition → Scientist anchors at city lab gate | **PASS** *(assisted: `mark_dating_overload_problem_recognized` + emit `problem_recognized`)* | Before recognition: anchors empty. After assisted recognition: `Spawned_girl_scientist` + `Spawned_rival_scientist` present; phone story «Учёная» / «Найти Учёную у закрытой лаборатории.»; lab travel blocked. Shot `02_city_scientist_gate.png` (weak visual — see notes). |
| 4 | After STAGE5 → lab travel; machine; calibration → WORK; total=1; rates 0 | **PASS** *(assisted: `restore_stage(STAGE_5)` + `mark_girl_conquered` + `complete_calibration_for_test` + `assign_work`)* | LABORATORY unlocked; travel laboratory SUCCESS; prompt `[E] Запустить установку клонирования`; sequence → assign WORK → `1/1/0`; `money_per_minute=0` `dates_per_minute=0`; machine done «Первый клон уже создан.»; physical representative present. Shots `03_lab_machine.png`, `04_lab_clone.png`. |
| 5 | Phone clone counts / Stage5 handoff | **PASS** | Pre-clone Stage5: «Лаборатория открыта. / Создай первого клона.» Post-clone: КЛОНЫ `Всего: 1 / На работе: 1 / На свиданиях: 0 / Свободных: 0`; story «Первый клон создан.»; no rates. Shot `05_phone_clones.png`. |
| 6 | No President; DatingOverload cap still 1/day | **PASS** | No `girl_president` / `rival_president`; no MODULE 18 spec/code dir; after clone + `mark_dating_overload_started`: one personal date → `BODY_CAPACITY_USED` on second; rates remain 0. |
| 7 | Screenshots opened/described (lab machine, clone, phone) | **PASS** | Three required PNGs opened and described below (+ apartment / city supporting). |
| 8 | Write `docs/agent/qa/M17_QA.md` | **PASS** | This file. |

---

## Player flow actually executed

1. Independent headless: `MODULE_17_TEST` ALL PASS (96).
2. Main-scene F5 smoke: boots apartment via World (quit-after).
3. Independent live harness `tmp/m17_qa/m17_indep_qa.tscn` (**62/62 PASS**):
   - World boot apartment + Neighbor; clones=0
   - STAGE_4 city_hub: scientist/rival anchors empty before recognition
   - **ASSISTED** recognition mark + `problem_recognized` emit → pair spawns; phone hunt text; lab blocked
   - **ASSISTED** STAGE_5 + scientist conquered → LABORATORY unlock → travel laboratory
   - Machine prompt available; **ASSISTED** calibration complete → WORK assign → `1/1/0`, rates 0
   - Phone Stage5 handoff + КЛОНЫ section; no President
   - Cap still 1/day; no MODULE 18
4. Opened and described evidence screenshots.

---

## Edge cases / notes

| Case | Status | Notes |
|------|--------|-------|
| GameState mark alone does not spawn anchors | **Note** | Anchors listen to `DatingOverload.problem_recognized`. Assisted harness emits that signal after mark (matches production recognition path). MODULE_17_TEST covers same via `_refresh_spawn`. |
| City gate screenshot weak | **Note** | Shot `02` is mostly empty/near transition HUD; spawn confirmed programmatically (PASS lines + report). Lab/clone/phone shots are the required visual set. |
| Dual PhoneJournal exclusive dialog | **Note** | Same harness noise as M16 when realization AcceptDialog overlaps; dismissed before world shots. Not a product criterion fail. |
| No MODULE 18 | **PASS** | No `MODULE_18_*` docs; no `game/clone_incremental`; rates stay 0; no President content. |
| Clean full F5 story grind | **Not re-run end-to-end** | Scientist rival/date +5 path covered by MODULE_17_TEST + content; live harness uses labeled STAGE_5 restore for lab/clone acceptance. |

---

## Screenshot descriptions (opened and inspected)

Evidence: `tmp/m17_qa/`

### 1) `01_apartment_boot.png` (supporting)

- Low-poly apartment; large label **«КВАРТИРА»**.
- Neighbor CharacterActor (blonde, white tee, orange pants).
- Date table + «Самооценка»; blue door; crosshair; HUD `mode=GAMEPLAY`.
- Matches F5 apartment boot.

### 2) `02_city_scientist_gate.png` (supporting)

- Weak visual: mostly empty grey field + player HUD `[E] В квартиру` / `target=ToApartment`.
- Does **not** clearly show Scientist models; spawn still verified in harness (`scientist/rival anchor spawned after recognition`).
- Not used as sole proof for criterion 3.

### 3) `03_lab_machine.png` **(required)**

- Laboratory grey room; translucent blue chamber + solid blue machine block.
- Labels **«КАЛИБРОВКА»** and **«УСТАНОВКА»**.
- HUD `mode=GAMEPLAY`; location context laboratory (ToCity target).
- Matches lab machine / calibration blockout after STAGE_5 travel.
- Machine interact prompt verified in log: `[E] Запустить установку клонирования` (player HUD in frame may show ToCity when near exit).

### 4) `04_lab_clone.png` **(required)**

- Same lab; male clone body on green **РАБОТА** pad.
- Overhead **«РАБОТА»**; chamber still labeled **«КАЛИБРОВКА» / «УСТАНОВКА»**; partial **«ЛАБО…»** location label.
- Matches WORK assignment physical representative (`total 1/1/0`).

### 5) `05_phone_clones.png` **(required)**

- Phone modal `mode=MODAL_UI`; title «Телефон — Журнал».
- Story: **СТАДИЯ 5 / Лаборатория** — «Первый клон создан.»
- **КЛОНЫ:** Всего: 1; На работе: 1; На свиданиях: 0; Свободных: 0.
- No President objective; no money/min or dates/min lines.
- Matches Phone clone counts + Stage5 post-clone handoff.

---

## Commands + key log lines

### Headless MODULE 17

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> --headless res://game/first_clone/test/first_clone_test.tscn --quit-after 40000
[DF][MODULE_17_TEST] ALL PASS (96)
MODULE_17_TEST: ALL PASS (96)
EXIT=0
```

Log: `tmp/m17_qa/first_clone_self_test.log`

### F5 main boot

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> --headless res://main.tscn --quit-after 8
[DF][MODULE_17] FirstClone ready
[DF][MODULE_12] Boot -> apartment via World
[DF][MODULE_01] Player ready
EXIT=0
```

Log: `tmp/m17_qa/f5_main_boot.log`  
(Exit leak noise from headless renderer teardown only.)

### Independent live QA + screenshots

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> res://tmp/m17_qa/m17_indep_qa.tscn
M17_INDEP_QA: DONE passed=62 failed=0
summary stage=5 recognized=true lab=true clones=1/1/0 mpm=0.0 dpm=0.0 assignment=1
EXIT=0
```

Log: `tmp/m17_qa/m17_indep_qa.log`  
Report: `tmp/m17_qa/m17_indep_qa_report.txt`  
Shots: `01_apartment_boot.png`, `02_city_scientist_gate.png`, `03_lab_machine.png`, `04_lab_clone.png`, `05_phone_clones.png`

---

## Unmet criteria

None for acceptance checklist.

## Recommendation

**PASS** — MODULE 17 First Clone Sequence meets acceptance; do not start MODULE 18.
