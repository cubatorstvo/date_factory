# M18_QA — MODULE 18 Independent QA

**Task:** M18_D_QA  
**Module:** 18 — Clone Incremental Core  
**Date:** 2026-08-08  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  
**Evidence:** `tmp/m18_qa/`  
**DoD:** `docs/modules/MODULE_18_CLONE_INCREMENTAL_CORE.md` §85

## Verdict

**PASS**

---

## Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Headless `clone_incremental_test.tscn` ALL PASS (~110) | **PASS** | `[DF][MODULE_18_TEST] ALL PASS (110)` EXIT=0. Log: `tmp/m18_qa/clone_incremental_self_test.log`. |
| 2 | MODULE_17 `first_clone` still PASS | **PASS** | `[DF][MODULE_17_TEST] ALL PASS (121)` EXIT=0. Log: `tmp/m18_qa/first_clone_self_test.log`. |
| 3 | F5 boots apartment | **PASS** | Main `res://main.tscn --quit-after 8`: `[DF][MODULE_12] Boot -> apartment via World`, CloneIncremental ready, Player ready. Indep: `reset_to_start` → `apartment`, Neighbor present. Shot `01_apartment_boot.png`. Log: `tmp/m18_qa/f5_main_boot.log`. |
| 4 | Assisted STAGE_5 + first clone WORK → lab → Clone Terminal prompt → modal counts/rates/upgrades | **PASS** | Travel laboratory SUCCESS; prompt `[E] Терминал клонов`; modal `КЛОН-ФАБРИКА` shows total/free/work/dating + money/dates rates + countdown + 3 upgrade tracks L0/5 cost 30. Shots `02_lab_terminal.png`, `03_terminal_modal.png`. Report: `tmp/m18_qa/m18_indep_qa_report.txt` (66/66). |
| 5 | `advance_simulation` free clones; rates non-zero; GameDay invents nothing | **PASS** | 30s → total 1→2 free +1; +60s → total 4; mpm=20; money 0→30 via sim. `advance_day` leaves clones/money/xp/assignment unchanged; stage stays 5. |
| 6 | Phone КЛОНЫ rates + Stage5 automation text | **PASS** | Phone shows `Денег/мин: 20`, `Свиданий/мин: 0`, counts; story «Автоматизация запущена. / Наращивай производство клонов.» Shot `04_phone_clones.png`. |
| 7 | No President / no MODULE 19 multi-slot viz / no offline | **PASS** | No `girl_president` / `rival_president`; no `MODULE_19_*` spec; no `clone_slots` / `physical_clones` dirs; single physical representative; no offline apply/catch_up/simulate methods on CloneIncremental. |
| 8 | Screenshots opened/described | **PASS** | All four evidence PNGs opened and described below. |
| 9 | Write `docs/agent/qa/M18_QA.md` | **PASS** | This file. |

---

## Player flow actually executed

1. Headless MODULE_18_TEST ALL PASS (110).
2. Headless MODULE_17_TEST ALL PASS (121).
3. Main-scene F5 smoke: boots apartment via World (quit-after 8).
4. Independent live harness `tmp/m18_qa/m18_indep_qa.tscn` (**66/66 PASS**, windowed):
   - World boot apartment + Neighbor; clones=0; incremental inactive
   - **ASSISTED** `restore_stage(STAGE_5)` + scientist conquered → LABORATORY unlock → travel laboratory
   - FirstClone calibration → `assign_work` → `1/1/0`, mpm=20, dpm=0, incremental active
   - Clone Terminal present; prompt `[E] Терминал клонов`; open modal → counts/rates/countdown/3 upgrades
   - `advance_simulation_for_test(30)` then `60` → free clones + money from work rate
   - `GameDay.advance_day` does not invent clones/money/xp
   - Phone КЛОНЫ rates + Stage5 automation handoff; no President
   - Boundaries: no MODULE 19 multi-slot dirs/spec; no offline APIs; single representative; terminal reopen / control return
5. Opened and described evidence screenshots.

---

## Edge cases

| Case | Status | Notes |
|------|--------|-------|
| GameDay invents incremental output | **PASS** | After sim to total=4 money=30, `advance_day` leaves total/working/dating/free/money/xp unchanged. |
| Terminal reopen / control return | **PASS** | Close modal → reopen `CloneTerminalUI` → close → `enter_gameplay`. |
| Incremental inactive at boot (0 clones) | **PASS** | `is_active()==false` after reset; active only after first clone. |
| Base production interval | **PASS** | Interval 30.0 s at L0. |

---

## Screenshot descriptions (opened and inspected)

Evidence: `tmp/m18_qa/`

### 1) `01_apartment_boot.png`

- Low-poly apartment; large label **«КВАРТИРА»**.
- Neighbor CharacterActor (blonde, white tee, orange pants) near blue door.
- Dating table «Стол для свидания»; «Самооценка» pillar; crosshair; HUD `mode=GAMEPLAY`.
- Matches F5 apartment boot.

### 2) `02_lab_terminal.png`

- Laboratory grey room; clone machine area labeled **«КАЛИБРОВКА» / «УСТАНОВКА»**.
- Physical terminal prop: light-blue screen block on dark base, overhead **«ТЕРМИНАЛ»**.
- HUD `mode=GAMEPLAY target=ToCity`; on-screen interact line shows **«[E] В город»** (player proximity to city exit, not the terminal).
- Terminal presence is visual; open-prompt `[E] Терминал клонов` verified programmatically in harness (not this HUD frame).

### 3) `03_terminal_modal.png`

- Modal title **«КЛОН-ФАБРИКА»**; HUD `mode=MODAL_UI`.
- Visible: Всего клонов: 1; Свободно: 0; На работе: 1; Денег в минуту: 20; На свиданиях: 0; Свиданий в минуту: 0.00; Следующий клон: 30.0 с.
- Assignment controls (−1 / +1 / Все свободные) for work and dating.
- Three upgrade tracks (ЛИНИЯ КОПИРОВАНИЯ / РАБОЧАЯ МЕТОДИКА / РОМАНТИЧЕСКИЙ КОНВЕЙЕР, Уровень 0/5, Улучшить — 30) confirmed in harness label dump; may sit below the cropped modal viewport in this PNG.

### 4) `04_phone_clones.png`

- Phone modal «Телефон — Журнал»; `mode=MODAL_UI`.
- Status: День 2; Деньги 30 (from simulated work output).
- Story: **СТАДИЯ 5 / Лаборатория** — «Автоматизация запущена. / Наращивай производство клонов.»
- **КЛОНЫ:** Всего: 4; Свободно: 3; Работают: 1; Денег/мин: 20; На свиданиях: 0; Свиданий/мин: 0.
- No President objective; read-only rates present.

---

## Commands + key log lines

### Headless MODULE 18

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> --headless res://game/clone_incremental/test/clone_incremental_test.tscn
[DF][MODULE_18_TEST] ALL PASS (110)
MODULE_18_TEST: ALL PASS (110)
EXIT=0
```

Log: `tmp/m18_qa/clone_incremental_self_test.log`

### Headless MODULE 17 regression

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> --headless res://game/first_clone/test/first_clone_test.tscn
[DF][MODULE_17_TEST] ALL PASS (121)
MODULE_17_TEST: ALL PASS (121)
EXIT=0
```

Log: `tmp/m18_qa/first_clone_self_test.log`

### F5 main boot

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> --headless res://main.tscn --quit-after 8
[DF][MODULE_18] CloneIncremental ready
[DF][MODULE_12] Boot -> apartment via World
[DF][MODULE_01] Player ready
EXIT=0
```

Log: `tmp/m18_qa/f5_main_boot.log`

### Independent live harness

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> res://tmp/m18_qa/m18_indep_qa.tscn
M18_INDEP_QA: DONE passed=66 failed=0
summary stage=5 clones=4/1/0/3 mpm=20.0 dpm=0.0 money=30 xp=0 interval=30.0
EXIT=0
```

Log: `tmp/m18_qa/m18_indep_qa_windowed.log`  
Report: `tmp/m18_qa/m18_indep_qa_report.txt`

---

## Limitations

- Clean full F5 story grind (recognition → scientist date → STAGE_5) not re-run end-to-end; live harness uses labeled STAGE_5 + first-clone WORK seed (same pattern as M17_QA).
- Lab terminal world shot HUD shows ToCity prompt due to player proximity; terminal open prompt verified by script, not that HUD line.
- Modal PNG may crop the upgrade block; upgrades verified via modal label/button text in harness.
- Full MODULE 02–16 regression battery not re-run in this QA pass (MODULE 17 + 18 suites + live flow only).
- Dedicated save/load roundtrip not independently re-run; MODULE_18_TEST covers reset clearing incremental runtime/levels/rates.

## Unmet criteria

None for the M18_D_QA must-verify list.

---

## Overall status

**PASS**

## Blocking issues

None.

## Non-blocking issues

- Terminal proximity HUD vs terminal prompt mismatch in `02_lab_terminal.png` (visual framing only).
- Modal upgrade section may be below fold in `03_terminal_modal.png`.

## Evidence

| Path | Role |
|------|------|
| `tmp/m18_qa/clone_incremental_self_test.log` | MODULE_18_TEST raw Godot log |
| `tmp/m18_qa/first_clone_self_test.log` | MODULE_17_TEST raw Godot log |
| `tmp/m18_qa/f5_main_boot.log` | Main boot raw Godot log |
| `tmp/m18_qa/m18_indep_qa_windowed.log` | Live harness raw Godot log |
| `tmp/m18_qa/m18_indep_qa_report.txt` | Capture journal / PASS lines |
| `tmp/m18_qa/01_apartment_boot.png` | Apartment boot |
| `tmp/m18_qa/02_lab_terminal.png` | Lab terminal prop |
| `tmp/m18_qa/03_terminal_modal.png` | Clone Terminal modal |
| `tmp/m18_qa/04_phone_clones.png` | Phone КЛОНЫ + Stage5 automation |
| `docs/agent/qa/M18_QA.md` | This report |

## Reproduction steps

1. Run headless MODULE_18 and MODULE_17 test scenes; confirm ALL PASS.
2. Run `res://main.tscn --quit-after 8`; confirm apartment boot.
3. Run windowed `res://tmp/m18_qa/m18_indep_qa.tscn`; confirm 66/66 and PNGs written under `tmp/m18_qa/`.
4. Open each PNG and confirm contents match the descriptions above.
