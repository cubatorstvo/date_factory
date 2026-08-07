# M13_D_QA — MODULE 13 Independent QA

**Task:** M13_D_QA  
**Module:** 13 — Salary Mine & Money Loop  
**Date:** 2026-08-07  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  

## Verdict

**PASS**

Critical player-visible money loop works in a real F5/main session. No critical defects found that break the MODULE 13 route.

Orchestrator recommendation: **READY** (acceptance uses READY / NOT READY).

---

## Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | F5 / main boot → apartment GAMEPLAY, no Foundation overlay | **PASS** | `World.current_location_id=apartment`, day=1, stage=0; screenshot boot shows `mode: GAMEPLAY`, no Foundation UI |
| 2 | Debug/restore STAGE_3 → initial pending > 0 | **PASS** | `restore_stage(STAGE_3)` → unlocked=true, pending=10, period=1, gross=10, level=1 |
| 3 | Travel apartment → city_hub → salary_mine; station prompt shows pending | **PASS** | `request_travel` SUCCESS; prompt `[E] Добыть зарплату — 10` |
| 4 | Manual claim ~1.5s → money↑, pending 0, manual_cycle_seen | **PASS** | `SalaryStation.interact()` → money 0→10, pending 0, manual=true, mode back to GAMEPLAY |
| 5 | Empty second claim does not pay | **PASS** | money stays 10; prompt `[E] Выплата уже добыта`; `claim_manual_pending` ok=false amount=0 |
| 6 | Return apartment → End Day → day↑, new pending | **PASS** | `DayAdvance.interact()` → day 1→2, pending 0→10, period 2, money unchanged 10, mode GAMEPLAY |
| 7 | Phone salary visible STAGE3; hidden before | **PASS** | STAGE2: section hidden / unlocked=false; STAGE3: visible with stats |
| 8 | CAPITAL_SALARY_ADVANCE: remote once/period, no manual_seen if false | **PASS** | Fresh reset+STAGE3+perk: claim_advance +10, manual=false, second advance fails; phone Advance controls visible+enabled |
| 9 | Financial Inertia after perk+manual_seen: floor 25% | **PASS** | gross=10 → day advance money +2, pending=8 |
| 10 | One `advance_day` decrements discovery/date once | **PASS** | discovered girl: disc 3→2→1, date 3→2→1 across two advances |
| 11 | Headless MODULE 13 + spot regressions | **PASS** (M13) / **WARNING** (FPS incomplete) | M13: ALL PASS (122); World: ALL PASS (127); GameState: ALL PASS (96); FPS headless exited after Player ready without ALL PASS line |
| 12 | Screenshots inspected | **PASS** | See screenshot descriptions below |

---

## Player flow actually executed

1. `godotiq_run(play, main)` — boot apartment GAMEPLAY.
2. Capture boot view (no Foundation overlay).
3. `GameState.restore_stage(STAGE_3)` — pending salary 10.
4. Open PhoneJournal — salary section visible with authority/rank/period/pending.
5. Close phone; `World.request_travel(city_hub)` then `salary_mine`.
6. Stand at SalaryStation; prompt shows pending 10; capture screenshot.
7. `station.interact(player)` — 1.5s claim cycle; money=10, pending=0, manual_seen=true; control returned.
8. Second interact — empty feedback, no extra pay.
9. Travel back apartment; `DayAdvance.interact(player)` — day overlay; day=2, pending=10.
10. Separate fresh-reset paths for Advance perk, Inertia, phone STAGE2 gate, cooldown double-decrement check.
11. Headless MODULE 13 + MODULE 12 + MODULE 02 self-tests.

---

## Commands + key log lines

### Headless MODULE 13

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> --headless res://game/salary/test/salary_mine_test.tscn --quit-after 180
[DF][MODULE_13] GameDay ready
[DF][MODULE_13] SalaryMine ready
[DF][MODULE_13_TEST] ALL PASS (122)
MODULE_13_TEST: ALL PASS (122)
EXIT=0
```

Log copy: `tmp/m13_qa/m13_headless.log` (also session stdout).

### Spot regressions

```text
res://world/test/world_location_test.tscn → MODULE_12_TEST: ALL PASS (127)
res://world/test/game_state_test.tscn → MODULE_02_TEST: ALL PASS (96)
res://world/test/player_fps_test.tscn → saw MODULE_01 Player ready; no ALL PASS within quit-after 600 (WARNING)
```

### Runtime state samples (GodotIQ exec)

```text
boot: apartment|0|0|1
STAGE3: unlocked=true pending=10 period=1 gross=10 level=1
travel: r1=0 loc1=city_hub r2=0 loc2=salary_mine
station prompt: [E] Добыть зарплату — 10
claim: money=10 pending=0 manual=true mode=GAMEPLAY
empty: money stays 10; prompt Выплата уже добыта
end day: day=2 pending=10 period=2 mode=GAMEPLAY
advance perk: claim ok amt=10 manual=false; second ok=false
inertia: money 10→12 (+2), pending=8, gross=10
cooldown: disc 3→2→1 ; date 3→2→1
phone STAGE2 vis=false; STAGE3 vis=true; Advance controls vis/enabled with perk
```

### Runtime console

No MODULE 13 script errors during QA play. Pre-existing AnimationMixer track warnings and an unrelated null-callable `is_connected` error appear in editor recent_errors (not introduced as MODULE 13 blockers in this session).

---

## Screenshot descriptions (opened and inspected)

Evidence files: `tmp/m13_qa/`

### 1) `end_day_prompt.png` (+ GodotIQ capture)

- Apartment-like low-poly room (tan floor, gray walls).
- Top-left debug: `mode=GAMEPLAY`.
- Center crosshair + prompt **`[E] Завершить день`**.
- No Foundation overlay, no phone modal.

### 2) `salary_station_prompt.png` (+ GodotIQ capture)

- Salary mine placeholder room; blue vertical station mesh centered.
- Top-left: `mode=GAMEPLAY`.
- Top-center large label reads **`АТХАШ`** (looks wrong/garbled for a location title — non-blocking visual WARNING).
- Prompt **`[E] Добыть зарплату — 10`** over the station.
- No Foundation overlay.

### 3) `phone_salary.png` (+ GodotIQ capture)

- Phone journal modal: header **«Телефон — Журнал»**, empty journal note.
- Salary block **«ЗАРПЛАТА · День 1»** with Авторитет 0 / Разряд 1 / За период 10 / Накоплено 10.
- Close button **«Закрыть»**.
- Debug mode line shows MODAL_UI (expected while phone open).

---

## Critical defects

None found on the MODULE 13 critical path.

---

## Non-blocking issues

1. **Location title in salary_mine shows `АТХАШ`** — visually wrong/garbled; does not block claim loop.
2. **Persistent FPS debug HUD** (`mode=GAMEPLAY target=...`) — not Foundation overlay, but still debug chrome in normal play.
3. **Placeholder visual fidelity** of apartment/mine (flat boxes) — acceptable for MODULE 13 systems POC; not a loop failure.
4. **FPS self-test incomplete in this QA session** — headless quit before ALL PASS line; World/GameState/M13 passed.
5. **GodotIQ `screenshot` sometimes timed out** inside mine; recovered via viewport PNG save + later successful GodotIQ captures.

---

## Limitations of this QA session

- Travel used `World.request_travel` (normal World API), not walking every city_hub door prop.
- Interaction prompts were force-shown on `FpsHud/PromptLabel` when raycast target was unreliable after teleport; claim/end-day themselves used real `Interactable.interact()`.
- Save/load persistence of salary fields was covered by headless MODULE 13 suite, not a separate F5 disk save round-trip in this session.
- Did not start MODULE 14.

---

## Recommendation to Orchestrator

**Accept MODULE 13 as PASS / READY.**

Independent runtime evidence confirms: STAGE_3 unlock → pending accrual → mine manual dig → empty re-claim safe → End Day advances day and accrues next period → Phone salary section gating → Salary Advance once/period without marking manual_seen → Financial Inertia 25% floor → single cooldown decrement per `GameDay.advance_day` → headless MODULE 13 ALL PASS (122).

Optional follow-ups (non-blocking): fix mine location title string `АТХАШ`; complete FPS suite run; strip/hide debug mode label for production builds.
