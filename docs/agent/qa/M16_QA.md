# M16_QA — MODULE 16 Independent QA

**Task:** M16_QA  
**Module:** 16 — Dating Overload  
**Date:** 2026-08-08  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  
**Evidence:** `tmp/m16_qa/`

## Verdict

**PASS**

---

## Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | `MODULE_16_TEST` ALL PASS | **PASS** | Headless `res://game/dating_overload/test/dating_overload_test.tscn` → `MODULE_16_TEST: ALL PASS (102)` EXIT=0. Log: `tmp/m16_qa/dating_overload_self_test.log`. |
| 2 | F5 apartment boots | **PASS** | Main scene `--quit-after 8`: `[DF][MODULE_12] Boot -> apartment via World`, DatingOverload ready, Player ready. Indep: `reset_to_start` → `apartment`, Neighbor present. Shot `01_apartment_boot.png`. Log: `tmp/m16_qa/f5_main_boot.log`. |
| 3 | Force/simulate `overload_ready` → DatingOverload starts with 3 overlapping 19:00/19:00/20:00 | **PASS** *(assisted: `restore_stage(STAGE_4)` + Media session + 3 publishes)* | Attention=45, offers=3, `Media.is_overload_ready`, DatingOverload started, demands=3, slots EARLY/EARLY/LATE → display `19:00,19:00,20:00`. Phone demand labels: WAITING 19:00 / 19:00 / 20:00. |
| 4 | Body capacity blocks second date same day | **PASS** | After one `apply_date_result`: `can_start_personal_date==false`; `get_date_availability` / `start_date_with_history` → `BODY_CAPACITY_USED`. |
| 5 | Phone shows ПЕРЕГРУЗКА + boost | **PASS** | `has_overload_section_visible`; summary «Сегодня можно лично посетить: 1… Невыполненный спрос: 3»; boost «Поднять волну» visible/enabled; use_feed_boost ok then disabled same day. Shot `02_phone_overload.png` (+ getters/log). |
| 6 | After recognition → realization text; stage stays 4; no Scientist | **PASS** | `problem_recognized`; story «Проблема не в графике. / Проблема в количестве меня.»; modal same lines + «Нужен способ физически находиться…»; `clone_solution_needed` once; `get_stage()==STAGE_4`; `try_get_girl/rival` scientist null; Laboratory locked; clones=0; no `game/first_clone` / `game/cloning`; no MODULE_17 docs. Shot `03_phone_realization.png`. |
| 7 | Open/describe 2–3 screenshots | **PASS** | Three PNGs opened and described below. |
| 8 | Write `docs/agent/qa/M16_QA.md` | **PASS** | This file. |

---

## Player flow actually executed

1. Independent headless: `MODULE_16_TEST` ALL PASS (102).
2. Main-scene F5 smoke: boots apartment via World (quit-after).
3. Independent live harness `tmp/m16_qa/m16_indep_qa.tscn` (**50/50 PASS**):
   - World boot apartment + Neighbor; overload inactive
   - Labeled assisted path: `restore_stage(STAGE_4)` + `complete_photo_session` + publish profile/chair/cover across days → Attention45, 3 offers, overload_ready
   - DatingOverload activation: 3 demands, 19:00/19:00/20:00
   - Phone MEDIA preserved + ПЕРЕГРУЗКА + Feed Boost
   - One personal date → second start blocked (`BODY_CAPACITY_USED`)
   - Advance days → recognition → realization story/modal; stage 4; no Scientist/Lab/clones/MODULE17
4. Opened and described all three evidence screenshots.

---

## Edge cases / notes

| Case | Status | Notes |
|------|--------|-------|
| Pre-overload unlimited dates | **PASS** | Covered by MODULE_16_TEST 114 (headless). |
| Recognition needs physical date + day≥start+2 | **PASS** | MODULE_16_TEST 129–130; indep: no recognition at start+1; recognizes after day+2 with prior personal date. |
| No MODULE 17 | **PASS** | No MODULE_17 spec docs; no `game/first_clone` / `game/cloning`; clones remain 0. |
| Dual PhoneJournal exclusive dialog (harness) | **Note** | Windowed harness can emit `Attempting to make child window exclusive…` when WorldHost PersistentUI PhoneJournal and test PhoneJournal both popup realization. Realization text still present; not a product criterion fail. |

---

## Screenshot descriptions (opened and inspected)

Evidence: `tmp/m16_qa/`

### 1) `01_apartment_boot.png`

- Grey/brown low-poly apartment; large label **«КВАРТИРА»**.
- Neighbor CharacterActor (blonde, white tee, orange pants).
- Date table + «Самооценка» props; blue door; crosshair; HUD `mode=GAMEPLAY`.
- Matches filename: apartment gameplay boot.

### 2) `02_phone_overload.png`

- Phone modal `mode=MODAL_UI`; title «Телефон — Журнал»; Day 3.
- Story: **СТАДИЯ 4 / Медийность** — «Входящих встреч: 3», «Лично успеваешь: 1 / день», «Спрос растёт быстрее тебя.»
- **МЕДИА:** `Внимание: 45 / 100`; three photos Опубликовано; three NEW incoming offers.
- Programmatic/UI scrape (same open): ПЕРЕГРУЗКА summary capacity 0/1, backlog 3, demand rows WAITING **19:00 / 19:00 / 20:00**, boost **Поднять волну**.
- Matches overload activation after assisted Media path.

### 3) `03_phone_realization.png`

- Phone Day 5; Attention 50/100; stage still **СТАДИЯ 4**.
- Story: «Проблема не в графике. / Проблема в количестве меня.» + next-step line.
- Center AcceptDialog with full realization:
  - «Проблема не в графике.»
  - «Проблема в количестве меня.»
  - «Нужен способ физически находиться в нескольких местах одновременно.»
- No Scientist content. Matches recognition criterion.

---

## Commands + key log lines

### Headless MODULE 16

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> --headless res://game/dating_overload/test/dating_overload_test.tscn --quit-after 40000
[DF][MODULE_16_TEST] ALL PASS (102)
MODULE_16_TEST: ALL PASS (102)
EXIT=0
```

Log: `tmp/m16_qa/dating_overload_self_test.log`

### F5 main boot

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> --headless res://main.tscn --quit-after 8
[DF][MODULE_16] DatingOverload ready
[DF][MODULE_12] Boot -> apartment via World
[DF][MODULE_01] Player ready
EXIT=0
```

Log: `tmp/m16_qa/f5_main_boot.log`  
(Exit leak noise from headless renderer teardown only.)

### Independent live QA + screenshots

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> res://tmp/m16_qa/m16_indep_qa.tscn
M16_INDEP_QA: DONE passed=50 failed=0
summary started=true recognized=true stage=4 att=50 offers=3 backlog=7 generated=8 personal=1 clones=0
EXIT=0
```

Log: `tmp/m16_qa/m16_indep_qa.log`  
Report: `tmp/m16_qa/m16_indep_qa_report.txt`  
Shots: `01_apartment_boot.png`, `02_phone_overload.png`, `03_phone_realization.png`

---

## Unmet criteria

None.

## Recommendation

**PASS** — MODULE 16 Dating Overload meets acceptance; do not start MODULE 17.
