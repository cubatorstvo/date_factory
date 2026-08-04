# EVENT-COOLDOWN-010 — Independent QA

**Task ID:** EVENT-COOLDOWN-010-QA  
**Date:** 2026-08-05  
**QA agent:** df-qa-worker (independent; did not trust implementation report)  
**Scope written:** this file only  
**Overall status:** **PASS**  
**Recommendation to Orchestrator:** **READY**

---

## Summary

Random ContentDB catalog events share one 10 in-game-minute gate (`last_random_event_abs_min` + `MIN_RANDOM_EVENT_INTERVAL_MIN = 10`) across passive `_process`, `trigger_random()`, and `maybe_trigger_after_date()`. After a successful catalog open at absolute minute **T = 1200**, eligibility is false at T / T+5 / T+9 and true at **T+10**. Save dictionary round-trip persists the stamp; old saves without the field are immediately eligible. Failed catalog opens and `open_runtime_event()` do not stamp the catalog interval. No parser errors; no catalog event spam during the session.

---

## Normal route / runtime session

| Step | Result |
|---|---|
| `godotiq_project_summary(detail=brief)` | DATE FACTORY, Godot 4, autoloads include `Game` |
| `godotiq_check_errors(scope=project)` | **0 errors / 95 scripts** |
| `godotiq_run(play, scene=main)` | Boot `res://scenes/boot/boot.tscn`, `runtime_attached=true` |
| Session setup | `Game.new_game()` → `run_started=true`, `stage_id=stage_1`, EventsAPI attached |
| Probes | Temporary runtime `stage_2` + paused time for catalog eligibility; **restored** to `stage_1`, stamp `-1`, active empty before stop |
| Stop | `godotiq_run(stop)` |

EventsAPI attachment (live): `Game.events` present; methods `trigger_random`, `maybe_trigger_after_date`, `_random_catalog_eligible`, `open_runtime_event`; `MIN_RANDOM_EVENT_INTERVAL_MIN = 10`.

Dating post-date caller (read-only): `modules/dating/dating_api.gd` → `Game.events.maybe_trigger_after_date(result)` after date finish. Post-date path was probed via that same API (seeded repeats), not a full date UI playthrough.

---

## Criterion-by-criterion

### 1. Project parse / check_errors
| Status | **PASS** |
|---|---|
| Evidence | `godotiq_check_errors(scope=project)` → `total: 0`, `scripts_checked: 95`. |
| Reproduction | Open project in GodotIQ → check_errors project scope. |

### 2. Normal launch + EventsAPI attached
| Status | **PASS** |
|---|---|
| Evidence | Play main/boot succeeded. `Game.events` Node attached; `interval=10`, `stamp=-1`, `has_trigger_random/has_maybe_after/has_eligible=true`. After `new_game()`: `run_started=true`. |
| Reproduction | Play main scene → confirm `Game.events` and interval const. |

### 3. After successful random catalog open at T: ineligible T..T+9, eligible T+10
| Status | **PASS** |
|---|---|
| Evidence | Opened catalog `prep_gift_swap` at **T = 1200**; `stamp_after_open = 1200`. Exact probes: |

| Offset | now | ago | eligible |
|---|---|---|---|
| T+0 | 1200 | 0 | **false** |
| T+5 | 1205 | 5 | **false** |
| T+9 | 1209 | 9 | **false** |
| T+10 | 1210 | 10 | **true** |

| Reproduction | Stamp via successful `open_event` → set abs minutes → call `_random_catalog_eligible()`. |

### 4. `trigger_random()` cannot open inside window
| Status | **PASS** |
|---|---|
| Evidence | At T+5 with stamp=T, active cleared: `trigger_random()` → `trigger_at_T5_opened=false`, stamp unchanged (1200), seen unchanged. |
| Reproduction | After catalog stamp, advance +5 min → `trigger_random()`. |

### 5. `maybe_trigger_after_date()` cannot bypass window
| Status | **PASS** |
|---|---|
| Evidence | At T+9 (`eligible=false`), 40 seeded calls to `maybe_trigger_after_date({"ok": true})` → **0 opens**, stamp unchanged. Gate runs before `randf()`, so probability cannot bypass. Shared gate also false at T+5/T+9, true at T+10. |
| Reproduction | Stamp catalog event → abs = T+9 → repeat `maybe_trigger_after_date` with varied seeds. |

### 6. Save dictionary round-trip (stamp persists, blocked at +5)
| Status | **PASS** |
|---|---|
| Evidence | `EventsAPI.to_dict()` includes `last_random_event_abs_min=1200`. After mutate-to-`-1` then `from_dict(saved)`: `load_stamp=1200`, `load_blocked_at_T5=true`. `Game.to_dict()["events"]` also carries stamp (`val=4242` probe then restored). `game.gd` wires `events.to_dict()` / `events.from_dict(...)`. |
| Reproduction | Stamp → `to_dict` → clear stamp → `from_dict` → check eligible at T+5. |

### 7. Old-save without field → immediately eligible
| Status | **PASS** |
|---|---|
| Evidence | `from_dict({"history": [], "seen": {}, "cooldown": 0.0})` → `old_save_stamp=-1`, `old_save_eligible=true`. |
| Reproduction | Load events dict omitting `last_random_event_abs_min`. |

### 8. Failed/empty opening does not stamp
| Status | **PASS** |
|---|---|
| Evidence | `open_event(&"__nonexistent_event_xyz__")` → stamp stays `-1`, active empty. Stage-1 `open_event(prep_gift_swap)` fails requires → stamp stays `-1`. |
| Reproduction | Call `open_event` with missing id or unmet `min_stage`. |

### 9. Clock backward/reset does not permanently block
| Status | **PASS** |
|---|---|
| Evidence | Stamp=T, abs set to T−30 (`backward_ago=-30`) → `backward_eligible=true`. |
| Reproduction | Set stamp ahead of current absolute minutes → check eligible. |

### 10. `open_runtime_event()` does not alter catalog stamp
| Status | **PASS** |
|---|---|
| Evidence | Stamp held at T; `open_runtime_event({id: qa_runtime_probe, ...})` → opened=true, **`runtime_stamp_unchanged=true`**, `cooldown=40.0` (wall-clock UI pacing only). |
| Reproduction | Set catalog stamp → open runtime event → compare `last_random_event_abs_min` and `cooldown`. |

### 11. At minute 10, time gate open; other gates remain
| Status | **PASS** |
|---|---|
| Evidence | At T+10: `_random_catalog_eligible()=true`. With `stage_1`, 20× `maybe_trigger_after_date` opens nothing and stamp stays T (stage gate). Back on `stage_2`: 13 content-eligible ids, `at10_content_and_time_ready=true`. |
| Reproduction | At T+10 verify time gate; drop to stage_1 and confirm post-date still blocked by stage. |

### 12. Debugger / stdout — errors and event spam
| Status | **PASS** (with known non-blocking nav noise) |
|---|---|
| Evidence | Script errors: **0**. No catalog event spam: restored idle `stage_1`, `stamp=-1`, `seen=0`, `hist=0`, `active` empty, `cooldown=0`. One NavigationServer map-sync runtime entry present from before/outside this feature (also seen at session start); not event-related. |
| Reproduction | Play → probe → `read_debug_console`; confirm no event flood. |

---

## Shared-gate coverage

| Path | Uses `_random_catalog_eligible()` | Independent result |
|---|---|---|
| Passive `_process` | Yes (before stage/rand) | Gate present in diff/runtime API |
| `trigger_random()` | Yes | Blocked at T+5 |
| `maybe_trigger_after_date()` | Yes | Blocked at T+9 (0/40) |
| `open_event` success | Stamps via `_stamp_random_catalog_opened()` | Stamp = T |
| `open_runtime_event` | Does **not** stamp catalog | Stamp unchanged; `cooldown=40` wall-clock |

---

## Engine logs

- **Parse:** 0 errors / 95 scripts (`check_errors` project).
- **Runtime console:** 1× NavigationServer `get_closest_point` map-sync message (pre-existing / non-event; severity error in debugger capture). No EventsAPI / missing-resource / script parse failures during probes.
- **Event spam:** none observed (no repeated catalog opens; idle state clean after restore).

---

## Blocking issues

None.

---

## Non-blocking issues

1. **NavigationServer map-sync** debugger entry — unrelated to catalog cooldown; already present at session start. Do not treat as EVENT-COOLDOWN-010 failure.

---

## Evidence

- Independent GodotIQ session: project_summary → check_errors → run(play main) → new_game → exec probes → state_inspect → read_debug_console → run(stop).
- Exact minute values: **T = 1200**; blocked at 1200/1205/1209; open at **1210**.
- Catalog open used: `prep_gift_swap` (stage_2 temporary for content requires; restored).
- Save wiring confirmed on `EventsAPI.to_dict/from_dict` and `Game.to_dict()["events"]`.
- Git working tree includes cooldown changes in `modules/events/events_api.gd` (reviewed via `git diff` for expected contract only; verdict from runtime probes).

---

## Reproduction steps

1. Launch project main scene (boot).
2. Start or continue so `Game` / `Game.events` / `Game.time` are live.
3. Ensure an eligible catalog event can open (stage ≥ 2, content requires met).
4. Note `T = Game.time.absolute_minutes()`, successfully `open_event` a catalog id (or `trigger_random` when eligible).
5. Confirm `Game.events.last_random_event_abs_min == T`.
6. At abs T, T+5, T+9: `_random_catalog_eligible()` is false; `trigger_random()` / `maybe_trigger_after_date()` do not open another catalog event.
7. At abs T+10: `_random_catalog_eligible()` is true (other stage/content gates still apply).
8. `events.to_dict()` → clear stamp → `from_dict` → stamp restored; old dict without field → stamp `-1` / eligible.
9. `open_runtime_event(...)` leaves `last_random_event_abs_min` unchanged and sets wall-clock `cooldown ≈ 40`.
10. Restore any temporary stage/time mutations; stop play.

---

## Overall

| Field | Value |
|---|---|
| Overall status | **PASS** |
| Orchestrator recommendation | **READY** |
| Critical route | Shared 10-minute catalog gate works for passive / trigger / post-date; save/old-save/runtime separation correct |
