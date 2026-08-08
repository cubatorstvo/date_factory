# QA Report — M24_FIX (prevalidate CloneIncremental runtime before mutation)

**Task:** MODULE 24 FIX — reject corrupt/invalid `runtime.clone_incremental` with `VALIDATION_FAILED` before any GameState / GameDay / CloneIncremental mutation  
**Date:** 2026-08-08  
**QA agent:** df-qa-worker (independent, read-only product code)  
**Godot:** `C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe` (4.7.1.stable)  
**Repo:** `C:\Users\User\Documents\GodotProjects\date_factory`

---

## 1. Summary

Acceptance blocker is fixed. Independent headless runs confirm:

- Pure `normalize_runtime_state` seam exists and is reused by `restore_runtime_state`.
- `SaveSystem._read_validate_payload` invokes that seam before returning `ok`.
- Corrupt negative runtime (`money_fraction=-1`, `elapsed=-0.1`, `date_fraction=-0.1`) yields `VALIDATION_FAILED` with live Money/Stage/Day/CI runtime untouched (covered inside `save_system_self_test`, ALL PASS 95).
- MODULE24 save IO / domain / world + MODULE18 clone regressions all EXIT=0.
- No MODULE25 started. No `SCRIPT ERROR` / `Parse Error` in QA logs.

**Recommendation to Orchestrator: PASS → READY** (Orchestrator decides final READY).

---

## 2. Commands executed

```powershell
$godot = "C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe"
$proj = "C:\Users\User\Documents\GodotProjects\date_factory"

& $godot --path $proj --headless --quit-after 60 "res://persistence/test/save_system_self_test.tscn"
& $godot --path $proj --headless --quit-after 60 "res://game/state/test/game_state_save_self_test.tscn"
& $godot --path $proj --headless --quit-after 90 "res://world/test/world_save_pose_test.tscn"
& $godot --path $proj --headless --quit-after 90 "res://game/clone_incremental/test/clone_incremental_test.tscn"
```

Evidence logs written under `tmp/m24_fix_qa/`.

---

## 3. Engine log paths + key lines

| Suite | Log | Key result | EXIT |
|-------|-----|------------|------|
| SaveSystem IO + corrupt no-mutation | `tmp/m24_fix_qa/save_system_self_test.log` | `MODULE_24_SAVE_IO_TEST: ALL PASS (95)` | 0 |
| GameState domain save | `tmp/m24_fix_qa/game_state_save.log` | `MODULE_24_DOMAIN_TEST: ALL PASS (88)` | 0 |
| World pose restore | `tmp/m24_fix_qa/world_pose.log` | `MODULE_24_WORLD_TEST: ALL PASS (28)` | 0 |
| CloneIncremental MODULE18 | `tmp/m24_fix_qa/clone_incremental.log` | `MODULE_18_TEST: ALL PASS (110)` | 0 |

Key extract: `tmp/m24_fix_qa/key_lines.txt`

### Grep: SCRIPT ERROR / Parse Error

Across all four QA logs: **none**.

Notes (non-blocking):

- `game_state_save.log` contains expected `push_error` from negative-path unit checks (`restore_day` day=0, `restore_runtime_state` rejected, invalid economy restore). Suite still ALL PASS.
- `world_pose.log` contains expected WARNINGs for invalid pose / unknown location fallback tests.
- Engine exit RID/ObjectDB leak noise in headless — pre-existing, not a test FAIL.

---

## 4. Code verification (independent read via GodotIQ)

| Check | Status | Evidence |
|-------|--------|----------|
| `CloneIncremental.normalize_runtime_state` exists | PASS | `game/clone_incremental/clone_incremental.gd` — pure Dictionary in/out; rejects missing keys, non-finite, negatives; wraps fractions to `[0,1)`; **no** writes to `_production_elapsed_seconds` / `_money_fraction` / `_date_fraction` |
| `restore_runtime_state` reuses normalizer | PASS | Calls `normalize_runtime_state`; on `!ok` returns false without mutation; only then assigns live fields + `recalculate_rates` / `_resolve_production_spawns` |
| `SaveSystem._read_validate_payload` prevalidates before ok | PASS | After key presence checks, calls `/root/CloneIncremental.normalize_runtime_state(ci)`; on `!ok` returns `VALIDATION_FAILED` / `"clone incremental runtime invalid"`; never reaches `_restore_validated_payload` |
| Regression covers required corrupt cases | PASS | `_test_corrupt_runtime_no_mutation` cases: `money_fraction=-1`, `production_elapsed_seconds=-0.1`, `date_fraction=-0.1`; asserts load `!ok`, `error == VALIDATION_FAILED`, live Money=77777, Stage=STAGE_1, Day=4, CI runtime snapshot unchanged; bak removed so backup recovery cannot mask |
| Non-finite unit coverage | PASS | `_test_normalize_runtime_rejects_non_finite` (NAN/INF/-INF) + wrap of fractions >1 |

---

## 5. Criteria table

| Criterion | Status | Evidence | Reproduction |
|-----------|--------|----------|--------------|
| Pure `normalize_runtime_state` (no mutation) | PASS | Code review; also exercised by save IO normalize unit checks | Read `clone_incremental.gd` normalize body |
| `restore_runtime_state` reuses same seam | PASS | Code review | Read `restore_runtime_state` |
| SaveSystem validates CI runtime in `_read_validate_payload` before restore | PASS | Code review | Read `_read_validate_payload` CI normalize block |
| Negative runtime → `VALIDATION_FAILED` | PASS | Covered in save IO suite ALL PASS (95) | Run `save_system_self_test.tscn` headless |
| Live Money / Stage / Day / CI untouched on reject | PASS | Regression asserts 77777 / STAGE_1 / day 4 + runtime equality per corrupt case | Same suite; cases labeled `money_fraction=-1`, `elapsed=-0.1`, `date_fraction=-0.1` |
| Non-finite rejected | PASS | Normalize unit test in same suite | Same suite |
| `save_system_self_test` ALL PASS | PASS | Log: ALL PASS (95), EXIT=0 | Command §2 |
| `game_state_save_self_test` ALL PASS | PASS | Log: ALL PASS (88), EXIT=0 | Command §2 |
| `world_save_pose_test` ALL PASS | PASS | Log: ALL PASS (28), EXIT=0 | Command §2 |
| `clone_incremental_test` ALL PASS | PASS | Log: ALL PASS (110), EXIT=0 | Command §2 |
| No SCRIPT ERROR / Parse Error | PASS | Grep of `tmp/m24_fix_qa/*.log` | Grep logs |
| No MODULE25 started | PASS | No `MODULE_25*` implementation files; ownership forbids MODULE25 | Filesystem + `docs/agent/OWNERSHIP.md` |
| STOP after fix (no MODULE25 work) | PASS | QA did not start MODULE25; product ownership status is M24 FIX only | Docs / ownership |

---

## 6. Edge cases checked

1. **Happy path still works:** roundtrip / fractions survive / bak recovery remain in save IO suite (ALL PASS).
2. **Corrupt money_fraction=-1:** VALIDATION_FAILED, live state untouched.
3. **Corrupt elapsed=-0.1:** VALIDATION_FAILED, live state untouched.
4. **Corrupt date_fraction=-0.1:** VALIDATION_FAILED, live state untouched.
5. **Non-finite (NAN/INF/-INF):** normalize returns `ok=false` (unit path).
6. **Repeated use / control return:** N/A for this persistence-only fix; covered by suite quit EXIT=0 without hang.

Screenshots: not applicable (headless persistence acceptance; no visual route change).

---

## 7. Unmet criteria

None for the MODULE 24 FIX acceptance list.

Non-blocking noise only: headless renderer RID leaks at exit; expected negative-path `push_error`/`WARNING` in domain/world tests.

---

## 8. Blocking issues

None.

---

## 9. Non-blocking issues

- Headless exit RID / ObjectDB leak spam (engine/scene teardown; EXIT still 0).
- Domain/world tests intentionally emit ERROR/WARNING lines for rejection paths — not SCRIPT/Parse failures.

---

## 10. Evidence

- `tmp/m24_fix_qa/save_system_self_test.log`
- `tmp/m24_fix_qa/game_state_save.log`
- `tmp/m24_fix_qa/world_pose.log`
- `tmp/m24_fix_qa/clone_incremental.log`
- `tmp/m24_fix_qa/key_lines.txt`
- Spec: `docs/modules/MODULE_24_FIX_PREVALIDATE_RUNTIME_BEFORE_MUTATION.md`
- Acceptance: `docs/agent/ACCEPTANCE.md`
- Architecture: `docs/persistence/SAVE_ARCHITECTURE.md`

---

## 11. Reproduction steps

1. Open repo `date_factory`.
2. Run the four headless commands in §2 with Godot 4.7.1 console.
3. Confirm each log ends with the ALL PASS line and process EXIT=0.
4. Confirm logs contain no `SCRIPT ERROR` / `Parse Error`.
5. Optionally inspect `persistence/test/save_system_self_test.gd` → `_test_corrupt_runtime_no_mutation` for the three corrupt fields and live-state assertions.

---

## 12. Overall status

| Field | Value |
|-------|-------|
| Overall status | **PASS** |
| Blocking issues | none |
| Recommendation | **PASS** — Orchestrator may mark READY |
| MODULE25 | not started (STOP observed) |

STOP. Do not begin MODULE25. Do not commit.
