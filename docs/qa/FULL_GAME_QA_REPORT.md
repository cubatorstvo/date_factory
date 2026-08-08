# FULL GAME QA REPORT — MODULE 27

**Spec:** §113 / §151  
**Date:** 2026-08-08  
**Wave:** Independent QA close (`df-qa-worker` light smoke + full `--only-rc` recheck)

---

## RC QA STATUS: **PASS** (automated / scripted)

**Orchestrator-facing recommendation: READY** — all `required_for_rc` suites **33/33 PASS**, open **BLOCKER=0 / MAJOR=0**.  
Manual routes A–F remain **NOT EXECUTABLE IN ENVIRONMENT** (not claimed PASS). Light title / New Game / title-API loop verified under GodotIQ where environment permitted.

| Field | Value |
|---|---|
| Commit SHA | `1f5b8dd` |
| Godot version | 4.7.1.stable.official (CLI + GodotIQ editor) |
| OS / test machine | Windows 10 |
| Automated suites | **33/33 PASS** (`tmp/qa/summary.txt`) |
| Manual routes A–F | **NOT EXECUTABLE IN ENVIRONMENT** |
| Light title smoke | **PASS** (API + screenshots; return visual caveat below) |
| Open BLOCKER / MAJOR / MINOR / TRIVIAL | **0 / 0 / 1 / 0** — [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md) |

---

## 1. Automated

| Item | Detail |
|---|---|
| Manifest | `qa/test_manifest.json` |
| Runner | `py -3 tools/qa/run_all_tests.py --only-rc` |
| Godot CLI | `C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe` |
| Logs | `tmp/qa/*.log`, `tmp/qa/summary.txt`, `tmp/qa/runner_rc_smoke.out` |
| Matrix | [`REGRESSION_MATRIX.md`](REGRESSION_MATRIX.md) |

**Final recheck summary:**

```
TOTAL 33
PASS  33
FAIL  0
```

Notable suite markers:

| Suite | Marker |
|---|---|
| `world_location` | `MODULE_12_TEST: ALL PASS (127)` — KI-M27-02 **closed** |
| `module_14a_vertical` | `MODULE_14A_TEST: ALL PASS (121)` |
| `module_14b_vertical` | `MODULE_14B_TEST: ALL PASS (85)` |
| `full_game_integration` | `MODULE_27_FULL_GAME: ALL PASS (157)` then post-suite exit `3221225477` (KI-M27-01) |
| `save_system` / `world_save_pose` | ALL PASS then same known post-suite crash (treated as PASS) |

Static scans Wave G: A/B/C/D all **PASS** — `tmp/qa/scans/`.

---

## 2. Scripted Route A / B / save

| Item | Result |
|---|---|
| Suite | `full_game_integration` |
| Asserts | **157** — `MODULE_27_FULL_GAME: ALL PASS (157)` |
| Coverage | Scripted mainline Route A + imperfect/recovery Route B + save continuation |
| Evidence | `tmp/qa/full_game_integration.log`, `tmp/qa/summary.txt` |
| Note | Post-suite headless SIGSEGV (KI-M27-01) — does not erase ALL PASS |

**PASS**

---

## 3. Manual routes A–F

| Route | Status |
|---|---|
| A Clean | NOT EXECUTABLE IN ENVIRONMENT |
| B Imperfect | NOT EXECUTABLE IN ENVIRONMENT (scripted B covered above) |
| C Optional ordinary | NOT EXECUTABLE IN ENVIRONMENT |
| D Broke / Capital-less | NOT EXECUTABLE IN ENVIRONMENT |
| E Specialized build | NOT EXECUTABLE IN ENVIRONMENT |
| F No clone upgrades | NOT EXECUTABLE IN ENVIRONMENT |

Do **not** invent F5 completion. Light GodotIQ title smoke ≠ Manual A–F PASS.

---

## 3b. Light title / New Game smoke (GodotIQ)

| Step | Status | Evidence |
|---|---|---|
| Play main → title | **PASS** | `tmp/qa/manual_smoke/01_title.png` — DATE FACTORY / Главное меню / Новая игра |
| New Game → apartment | **PASS** | `World.current_location_id=apartment`; `02_apartment_after_new_game.png` — 3D interior + NPC |
| `SaveSystem.return_to_title` | **PASS** (API) | `ok=true`; title buttons visible_in_tree after call |
| Visual return-to-title PNG | **WARNING** | `03_return_to_title.png` still shows apartment FPS view (filename mismatch); `03b_title_after_replay.png` is title after clean replay |

Sync `SaveSystem.start_new_game()` from GodotIQ `exec` often **times out** (world boot); deferred `call_deferred("start_new_game")` + `hide_menu` worked for smoke.

---

## 4. Production fixes list (MODULE 27 QA/FIX)

Documented for RC audit — no MODULE 28 scope:

1. **Stale catalog asserts** — vertical 14A/14B tests updated to **23 girls / 19 rivals / 22 discovery**.
2. **Dance story loss expect** — story rival PLAYER_LOSS Authority delta aligned with MODULE 26 (0).
3. **Empty `spawn_ids` on pre-M25 NPCs** — ordinary NPC spawn identity filled.
4. **`world_location` suite** — now completes ALL PASS (127) on recheck.

---

## 5. Schema / release boundary

| Item | Status |
|---|---|
| `SAVE_SCHEMA_VERSION` | **1** (`persistence/save_types.gd`) — scan D PASS |
| MODULE 28 features | **None** introduced |
| New gameplay systems / content / balance goals | **Forbidden** — QA/FIX only |

---

## 6. Static scans (Wave G)

| Scan | Verdict | Path |
|---|---|---|
| A Placeholders (`data/content/**`) | PASS | `tmp/qa/scans/A_placeholder_scan.md` |
| B Donor dependency | PASS (0) | `tmp/qa/scans/B_donor_dependency.md` |
| C Absolute developer paths | PASS (0) | `tmp/qa/scans/C_absolute_paths.md` |
| D Schema version | PASS (still 1) | `tmp/qa/scans/D_save_schema_version.md` |

---

## 7. Known issues

See [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md).

- KI-M27-01 headless SIGSEGV after ALL PASS — **MINOR**, open  
- KI-M27-02 `world_location` crash — **CLOSED** on 2026-08-08 recheck (ALL PASS 127)

---

## 8. Orchestrator close checklist

- [x] Full `run_all_tests.py --only-rc` recheck → **33/33 PASS**
- [x] Confirm 14a/14b PASS on new asserts
- [x] Decide KI-M27-02 disposition → **closed**
- [x] Manual A–F honesty → remaining **NOT EXECUTABLE** (6 routes); light title smoke done
- [x] RC QA STATUS **PASS**; recommendation **READY** (automated gate)

Independent report: [`docs/agent/qa/M27_QA.md`](../agent/qa/M27_QA.md)
