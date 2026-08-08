# KNOWN ISSUES — MODULE 27 Full Game QA

**Spec:** `docs/modules/MODULE_27_FULL_GAME_QA.md` §112  
**Date:** 2026-08-08  
**Open counts (independent QA recheck):**

| Severity | Open |
|---|---|
| BLOCKER | **0** |
| MAJOR | **0** |
| MINOR | 1 (non-blocking, release-decidable) |
| TRIVIAL | 0 |

No open BLOCKER or MAJOR. Automated `required_for_rc` = **34/34 PASS** (post-MODULE 28).

---

## KI-M27-01 — Headless SIGSEGV after ALL PASS

| Field | Value |
|---|---|
| ID | KI-M27-01 |
| Severity | MINOR |
| Area | Headless QA / engine teardown |
| Reproduction | Run several `required_for_rc` suites via `tools/qa/run_all_tests.py`. Suite prints `ALL PASS (N)`, then process exits with Windows code `3221225477` / CrashHandler signal 11 during ObjectDB/resource cleanup. Observed on e.g. `full_game_integration`, `save_system`, `world_save_pose` (2026-08-08 recheck). |
| Impact | Does not invalidate assertion results when `ALL PASS` appears before the crash. Runner treats these as PASS when configured. No known player-facing gameplay break. |
| Workaround | Treat post-suite engine crash as known harness noise; rely on `ALL PASS` marker + runner classification. |
| Release decision | Accept for RC; track as engine/teardown hygiene, not product blocker. MODULE 28 exported smoke: window close exit=0 — treat as headless-only. |

---

## KI-M27-02 — `world_location` engine crash (CLOSED)

| Field | Value |
|---|---|
| ID | KI-M27-02 |
| Severity | ~~MINOR~~ **CLOSED** |
| Area | World / M12 headless suite |
| Status | **CLOSED** 2026-08-08 — recheck `MODULE_12_TEST: ALL PASS (127)` (`tmp/qa/world_location.log`), runner PASS, exit=0. |
| Prior evidence | Earlier Wave G log crashed with signal 11 before ALL PASS. |
| Release decision | Closed; no longer gates RC. |

---

## Manual routes A–F (status, not defects)

| Route | Status |
|---|---|
| A Clean | **NOT EXECUTABLE IN ENVIRONMENT** |
| B Imperfect | **NOT EXECUTABLE IN ENVIRONMENT** — scripted imperfect/recovery covered by full_game_integration |
| C Optional ordinary | **NOT EXECUTABLE IN ENVIRONMENT** |
| D Broke / Capital-less | **NOT EXECUTABLE IN ENVIRONMENT** |
| E Specialized build | **NOT EXECUTABLE IN ENVIRONMENT** |
| F No clone upgrades | **NOT EXECUTABLE IN ENVIRONMENT** |

Honesty rule: do not invent F5 completion. Light title/New Game GodotIQ smoke ≠ Manual A–F PASS.

---

## Closed / fixed during MODULE 27 (reference)

| Topic | Notes |
|---|---|
| Stale catalog asserts (14a/14b) | Recheck PASS: 14A ALL PASS (121), 14B ALL PASS (85). |
| Dance story loss Authority expect | Aligned with MODULE 26 (story loss Auth delta 0). |
| Empty `spawn_ids` on pre-M25 NPCs | Production/content wiring fixed. |
| KI-M27-02 world_location crash | Closed on full `--only-rc` recheck. |

Evidence scans: `tmp/qa/scans/`.
