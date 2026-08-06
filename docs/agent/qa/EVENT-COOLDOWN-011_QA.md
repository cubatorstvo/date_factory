# EVENT-COOLDOWN-011 — Independent QA

**Task ID:** EVENT-COOLDOWN-011-QA  
**Date:** 2026-08-05  
**QA agent:** df-qa-worker (independent; did not trust implementation report)  
**Scope written:** this file only  
**Overall status:** **PASS**  
**Recommendation to Orchestrator:** **READY**

---

## Summary

Automatic `open_runtime_event` (including clone deferred «Последствие пропуска») shares the same 10 in-game-minute stamp gate as catalog randoms (`last_random_event_abs_min` + `MIN_RANDOM_EVENT_INTERVAL_MIN = 10`). After a successful auto open at absolute minute **T**, `can_open_auto_event` is false at T / T+5 / T+9 and true at **T+10**. While gated, `deferred_hits` do not burn `due` and do not spam; at +10 with due ready, exactly one consequence fires. Player-initiated opens (`player_initiated=true`, phone booking path) succeed inside the window and restamp. Save/load round-trips stamp + deferred queue. No debugger event spam. Temporary probe mutations restored; game stopped cleanly.

---

## Normal route / runtime session

| Step | Result |
|---|---|
| `godotiq_project_summary(detail=brief)` | DATE FACTORY, Godot 4, autoloads: GodotIQRuntime, EventBus, SettingsService, Game |
| `godotiq_check_errors(scope=project)` | **0 errors / 95 scripts** |
| `godotiq_run(stop)` then `play(scene=main)` | Boot → `main.tscn`, `runtime_attached=true` |
| Session setup | `Game.new_game()` → `run_started=true`, `stage_id=stage_1`, time paused for minute probes |
| Probes | Independent `godotiq_exec` against EventsAPI / ClonesAPI; temporary `stage_2` for catalog only |
| Debug console | `runtime_errors_total=0`, `script_errors_total=0`, entries=[] |
| Restore | Cleared active/stamp/deferred; `Game.new_game()` → clean `run_started=true`, stamp=-1 |
| Stop | `godotiq_run(stop)` |

Live API: `MIN_RANDOM_EVENT_INTERVAL_MIN=10`, `can_open_auto_event()`, `open_runtime_event(ev, player_initiated=false)`, clones `_tick_deferred_hits` pauses when `not can_open_auto_event()` or active event present. Phone UI calls `open_runtime_event(..., true)` (verified via `phone_ui.gd` read).

---

## Criterion-by-criterion

### 1. Project parse clean
| Status | **PASS** |
|---|---|
| Evidence | `godotiq_check_errors(scope=project)` → `total: 0`, `scripts_checked: 95`. |
| Reproduction | GodotIQ → check_errors project. |

### 2. Successful auto `open_runtime_event` stamps; `can_open_auto_event` false until +10
| Status | **PASS** |
|---|---|
| Evidence | At **T = 1200**, auto open `qa_auto_rt_011` → `auto_opened=true`, `stamp_after_auto=1200`, `can_auto_at_T=false`. Exact gate table: |

| Offset | now | ago | can_auto |
|---|---|---|---|
| T+0 | 1200 | 0 | **false** |
| T+5 | 1205 | 5 | **false** |
| T+9 | 1209 | 9 | **false** |
| T+10 | 1210 | 10 | **true** |

Auto open at T+5 → `false`, stamp unchanged 1200. Auto open at T+10 → `true`, stamp restamped to **1210**.

| Reproduction | Pause time → set abs minutes → `open_runtime_event(..., false)` → clear active → probe `can_open_auto_event` at offsets. |

### 3. Clone deferred: due not burned while gated; at +10 one consequence fires
| Status | **PASS** |
|---|---|
| Evidence | Stamp at **T = 1300**; inject two hits `due=[0.5, 1.0]`. At T+3, 20× `_tick_deferred_hits(0.5)` → `due_preserved=true` (`[0.5, 1.0]` unchanged), `queue_n_while_gated=2`, no active. At T+10 one tick → active name **`Последствие пропуска: Волосы другого оттенка`**, `queue_n_after_one_fire=1`, stamp **1310**. While active, further ticks: `spam_due_preserved=true`. After clear still gated: remaining due paused. Separate probe with `due=0` while gated: preserved; at T+10 fires **`Последствие пропуска: Перепутанный маршрут`**, queue emptied. |
| Reproduction | Stamp auto runtime → inject `deferred_hits` → tick while gated → advance +10 → tick once. |

### 4. Queue survives across the wait
| Status | **PASS** |
|---|---|
| Evidence | During gate: queue size stayed 2, dues unchanged. After one fire: second hit remained (`due=5.0` reschedule for already-due sibling). After load: `load_deferred_n=1`, `load_due=7.5`, `load_due_preserved=true` under gate. |
| Reproduction | See §3 and §7. |

### 5. Player-initiated phone path opens inside window and restamps
| Status | **PASS** |
|---|---|
| Evidence | Stamp at **Tp = 1500**, now **1503** (`can_auto_inside=false`). Auto open → `false`. `open_runtime_event(book_date_*, true)` → `player_initiated_opened=true`, `player_active_id=book_date_qa_cafe`, `player_stamp=1503`, `player_restamped=true`. Auto after phone still blocked; second player open immediately → `player_second_open=true`, stamp **1503**. Matches `phone_ui.gd` call site (`player_initiated=true`). |
| Reproduction | Set stamp → advance +3 → `open_runtime_event(..., true)`. Full phone UI click not required; same API flag. |

### 6. Catalog auto path shares same stamp gate
| Status | **PASS** |
|---|---|
| Evidence | Temporary `stage_2`. Catalog `prep_gift_swap` at **Tc = 1600** stamps 1600. At Tc+5: `can_auto=false`, runtime auto blocked, `trigger_random()` opens nothing, stamp still 1600. Reverse: runtime stamp at **Tr = 1700** blocks `trigger_random` at Tr+4; `can_auto` true at Tr+10. |
| Reproduction | Stamp via `open_event` / `open_runtime_event` → cross-check opposite path at +5 / +10. |

### 7. Save/load of stamp + deferred_hits
| Status | **PASS** |
|---|---|
| Evidence | Stamp **Ts = 1800**, deferred `due=7.5`. `events.to_dict()` → `last_random_event_abs_min=1800`. `clones.to_dict()` → 1 hit due 7.5. `Game.to_dict()` carries both. After clear + `from_dict`: `load_stamp=1800`, `load_due=7.5`, blocked at +5, due preserved under gate ticks. Old save without stamp field → stamp=-1, eligible=true. |
| Reproduction | Populate → `to_dict` → mutate → `from_dict` → probe gate + queue. |

### 8. No event spam in debugger
| Status | **PASS** |
|---|---|
| Evidence | `godotiq_read_debug_console` after probes: `total=0`, `runtime_errors_total=0`, `script_errors_total=0`. Gated deferred spam loop (10 ticks while active / while gated) produced no extra opens. |
| Reproduction | Run probes → read_debug_console. |

### 9. Restore temporary runtime mutations before stop
| Status | **PASS** |
|---|---|
| Evidence | Cleared active/cooldown/stamp/deferred; `Game.new_game()` → `run_started=true`, `stamp=-1`, `deferred_n=0`, `stage_1`. Then `godotiq_run(stop)`. |
| Reproduction | End of session restore exec + stop. |

---

## Edge cases

| Case | Status | Evidence |
|---|---|---|
| Active event UI blocks next deferred fire | **PASS** | After first fire, 10 ticks with active: queue stayed 1, due unchanged |
| Clock backward does not permanent-block | **PASS** | Stamp=Tr, now=Tr−30 → `backward_eligible=true` |
| `due=0` while gated does not spam/consume | **PASS** | 5 ticks at T+5 kept due=0 and queue; fire only at T+10 |
| Old save missing stamp | **PASS** | Immediately eligible |

---

## Limitations (non-blocking)

- Phone booking verified via `open_runtime_event(..., true)` (identical flag/`book_date_` shape used by `phone_ui.gd`), not a full phone UI click-through.
- «Последствие пропуска» verified by setting `active.name` / API fire, not by screenshot of the event popup widget.
- Catalog probe used temporary `stage_2` + `prep_gift_swap` (restored).

---

## Blocking issues

None.

## Non-blocking issues

None material. NavigationServer map sync noise appeared once in editor `_editor_state.recent_errors` from an earlier session; post-probe debug console capture was empty.

---

## Evidence bundle

- GodotIQ: `project_summary` → `check_errors(project)` → `run(play)` → multiple `exec` probes → `read_debug_console` → restore → `run(stop)`.
- Exact minutes: auto gate T=**1200**; deferred T=**1300** / fire stamp **1310**; phone Tp=**1500**/now **1503**; catalog Tc=**1600**; runtime/catalog cross Tr=**1700**; save Ts=**1800**.
- Interval constant: **10** game minutes.

---

## Reproduction steps

1. `godotiq_check_errors(scope=project)` — expect 0.
2. `godotiq_run(play, scene=main)`; `Game.new_game()`; `Game.time.paused = true`.
3. Set `Game.time.day=1`, `minutes=1200`; `open_runtime_event({id:…}, false)` → stamp=1200; clear active; assert `can_open_auto_event` false at +0/+5/+9, true at +10.
4. Stamp at 1300; inject `Game.clones.deferred_hits` with small dues; call `_tick_deferred_hits` many times at +3 → dues unchanged; at +10 one «Последствие пропуска» opens.
5. At stamp+3, `open_runtime_event(..., false)` fails; `open_runtime_event(..., true)` opens and restamps.
6. With stage_2, catalog open stamps; blocks auto runtime / `trigger_random` until +10; reverse with runtime stamp.
7. `events.to_dict` / `clones.to_dict` / reload → stamp + deferred due preserved; gate still holds at +5.
8. Clear mutations / `new_game`; `read_debug_console`; `run(stop)`.

---

## Final decision

**READY**
