# M26 QA — MODULE 26 Balance / Anti-Grind

**Task id:** M26  
**Date:** 2026-08-08  
**QA role:** Independent `df-qa-worker` (no product-code changes)  
**Repo:** `C:\Users\User\Documents\GodotProjects\date_factory`  
**Godot:** `C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe`  
**Specs:** `docs/modules/MODULE_26_BALANCE_ANTI_GRIND.md` §128 · `docs/agent/ACCEPTANCE.md` · `docs/balance/BALANCE_REPORT.md`

---

## Overall status

**READY**

Independent code audit + headless harnesses confirm the MODULE 26 anti-grind story-loss rule, UI stakes copy, balance budgets (≥30 PASS), schema v1, and sampled MODULE02–25 regressions. No MODULE27 redesign / no Types retune in production.

---

## Criteria

| # | Criterion | Status | Evidence | Reproduction |
|---|---|---|---|---|
| 1 | Story rival loss: `is_story` → `authority_delta` 0 | **PASS** | `rival_encounters.gd` `_resolve_competition_result` loss branch sets `authority_delta = 0` when `def.is_story`; suite `MODULE_06_TEST: ALL PASS (183)` including all 5 Earth story rivals | See §Reproduction · rival_encounter_test |
| 2 | Ordinary loss still −1; exhibition 0 | **PASS** | Ordinary: `_test_ordinary_loss_still_minus_one` (5→4, delta −1). Exhibition: M21 exhibition win/loss leave Auth unchanged (no `RivalEncounters` mutation). Heroic ordinary still 0 via perk branch | Same log |
| 3 | UI stakes story vs ordinary | **PASS** | `rival_encounter_ui.gd` `_stakes_text`: story → `Поражение: Авторитет не меняется`; ordinary default → `Поражение: Авторитет -1`; exhibition → `Авторитет не меняется` | Code read + git diff (UI-only stakes change) |
| 4 | `balance_test.tscn` ALL PASS (≥30); record President/Stage6 times | **PASS** | `MODULE_26_BALANCE: ALL PASS (30)`. Measured: President A **269.0s**, B **359.0s**, C **329.0s**; Stage6 no-upgrade **436.0s**; Stage6 events **344.0s**; Combined **795.0s**; LocalUpgrade30 **90.0s** | See §Reproduction · balance_test |
| 5 | BALANCE_REPORT: only production change story loss −1→0; no Types retune | **PASS** | Report §4: “Earth story rival loss: Authority -1 → 0” / “no other production constants were retuned.” Git: Types / salary / media / overload / save_types **unchanged**; product diff only `rival_encounters.gd` + `rival_encounter_ui.gd` (+ test harness/docs) | Report + `git diff` |
| 6 | `SAVE_SCHEMA_VERSION == 1` | **PASS** | `persistence/save_types.gd` const = 1; balance harness asserts `SAVE_SCHEMA_VERSION == 1` | Code + balance log |
| 7 | Sample regressions | **PASS** | content_data 649 · dating 270 · clone_incremental 110 · late_game 101 · media 146 · story 85 · final_date 78 · save_system 138 (all ALL PASS) | §Reproduction · regressions |
| 8 | No MODULE27 redesign / no new content systems | **PASS** | Scope = story-loss rule + UI text + `game/balance/test/*` + docs. No new currencies/stages/perks/content catalogs; Types files not modified | git status / diff |
| 9 | No `SCRIPT ERROR` / `Parse Error` in QA logs | **PASS** | Grep across `tmp/m26_qa/*.log` → 0 matches | `tmp/m26_qa/` |

### Edge cases (independent)

| Edge | Status | Notes |
|---|---|---|
| All 5 Earth story losses leave Auth + retry legal | **PASS** | Covered in rival suite M26 story loop |
| Ordinary loss floor / −1 | **PASS** | Auth 5→4; delta −1 |
| Exhibition Auth mutation | **PASS** | Exhibition seam Auth unchanged (win + loss) |
| Main boot | **PASS** | Headless `--quit-after 8` EXIT=0; all listed autoloads ready |
| Save suite exit teardown | **WARNING** | Suite prints `ALL PASS (138)` then `CrashHandlerException` signal 11 (exit −1073741819). Reproduced twice. Assertions passed; crash is post-suite teardown. Not introduced by MODULE 26 product diff (no `persistence/` changes). |

---

## Blocking issues

None.

---

## Non-blocking issues

1. **SaveSystem self-test exit crash (signal 11)** after `ALL PASS (138)` — teardown/leak crash; does not fail assertions. Pre-existing relative to M26 product files. Deferred cleanup / MODULE 27 Full Game QA ownership if still present in F5.
2. **Rival exhibition probe ERROR** in rival log: `[RivalCompetitionRunner] exhibition supports only SLAP/DANCE, got=2` — expected rejection path in suite; suite still ALL PASS.
3. **ContentDB intentional missing_girl ERROR** during content_data negative test — suite ALL PASS.
4. Godot headless resource/ObjectDB leak warnings on several suites — non-functional for this milestone.
5. Full F5 manual routes A–F / natural 5–8 h timing — deferred by BALANCE_REPORT §8–§9 to MODULE 27 (acceptable for M26 balance lock).

---

## Evidence

Directory: `tmp/m26_qa/`

| File | Result |
|---|---|
| `rival_encounter_test.log` | `MODULE_06_TEST: ALL PASS (183)` EXIT=0 |
| `balance_test.log` | `MODULE_26_BALANCE: ALL PASS (30)` + MEASURED times |
| `content_data_test.log` | `MODULE_03_TEST: ALL PASS (649)` |
| `dating_test.log` | `MODULE_09_TEST: ALL PASS (270)` |
| `clone_incremental_test.log` | `MODULE_18_TEST: ALL PASS (110)` |
| `late_game_test.log` | `MODULE_20_TEST: ALL PASS (101)` |
| `media_test.log` | `MODULE_15_TEST: ALL PASS (146)` |
| `story_test.log` | `MODULE_11_TEST: ALL PASS (85)` |
| `final_date_test.log` | `MODULE_21_TEST: ALL PASS (78)` |
| `save_system_test.log` | `MODULE_24_SAVE_IO_TEST: ALL PASS (138)` then exit crash |
| `save_system_test_rerun.log` | Same ALL PASS + signal 11 |
| `f5_main_boot.log` | Autoloads ready, EXIT=0 |
| `summary.txt` | Condensed independent run record |

### Code audit (not executor trust)

```text
game/rivals/rival_encounters.gd
  loss: if def.is_story → authority_delta = 0
        else heroic → 0 else lose_authority(1)

ui/rivals/rival_encounter_ui.gd
  story stakes: "Поражение: Авторитет не меняется"
  ordinary: "Поражение: Авторитет -1" (heroic perk softens copy)

persistence/save_types.gd
  SAVE_SCHEMA_VERSION = 1

docs/balance/BALANCE_REPORT.md
  only production rule change: story loss −1 → 0
```

### Measured balance budgets (this QA run)

| Budget | Measured | Limit |
|---|---|---|
| President A | 269.0 s | ≤390 |
| President B | 359.0 s | ≤390 |
| President C | 329.0 s | ≤390 |
| Stage6 no-upgrade | 436.0 s | ≤480 |
| Stage6 + events | 344.0 s | ≤390 |
| Combined | 795.0 s | ≤900 |
| Local first upgrade | 90.0 s | ≤90 |

Matches BALANCE_REPORT §5 measured harness table.

---

## Reproduction steps

```powershell
$godot = "C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe"
cd C:\Users\User\Documents\GodotProjects\date_factory

# Story / ordinary / exhibition Authority rules
& $godot --path . --headless res://game/rivals/test/rival_encounter_test.tscn
# expect: MODULE_06_TEST: ALL PASS (183)

# Balance lock
& $godot --path . --headless res://game/balance/test/balance_test.tscn
# expect: MODULE_26_BALANCE: ALL PASS (30) + MEASURED President/Stage6 lines

# Sample regressions
& $godot --path . --headless --quit-after 120000 res://world/test/content_data_test.tscn
& $godot --path . --headless --quit-after 120000 res://game/dating/test/dating_test.tscn
& $godot --path . --headless --quit-after 120000 res://game/clone_incremental/test/clone_incremental_test.tscn
& $godot --path . --headless --quit-after 120000 res://game/late_game/test/late_game_test.tscn
& $godot --path . --headless --quit-after 120000 res://game/media/test/media_test.tscn
& $godot --path . --headless --quit-after 120000 res://game/story/test/story_test.tscn
& $godot --path . --headless --quit-after 120000 res://game/final_date/test/final_date_test.tscn
& $godot --path . --headless --quit-after 120000 res://persistence/test/save_system_self_test.tscn

# Main boot smoke
& $godot --path . --headless --quit-after 8

# Grep
Select-String -Path tmp\m26_qa\*.log -Pattern "SCRIPT ERROR|Parse Error"
```

---

## Verdict

**PASS → READY**

MODULE 26 Balance / Anti-Grind meets acceptance for release-candidate constant lock and story-loss anti-grind. Remaining Full Game F5 / natural-run timing belongs to MODULE 27, not M26 blockers.
