# PE01-BLIND-A-B — Independent QA Report

**Task id:** PE01-BLIND-A-B  
**Role:** df-qa-worker (source-blind Phase A)  
**Dates:** 2026-08-09 initial + 2026-08-09 environment-recovery re-run  
**Baseline:** `86cb0f9`  
**Gameplay mutation:** none  
**GodotIQ / Story / state APIs used for play:** none  

---

## Summary (read this first)

Phase A has **two evidence layers**. Do not conflate them.

| Layer | What it proves | Verdict |
|---|---|---|
| **Initial A/B** (`userdata_A` / `userdata_B`) | With **missing `.godot` launch cache**, CLI window was blank gray; parse/autoload failure in raw logs; Main Menu never appeared | **Launch-infrastructure FAIL** (not a gameplay onboarding measurement) |
| **Recovery A/B** (`userdata_A_recovery` / `userdata_B_recovery`) — **authoritative baseline** | Cache restored; Main Menu → New Game works; first-time player cannot reach Neighbor / prologue | **Gameplay onboarding FAIL** |

**Authoritative Phase A player-route recommendation: FAIL / NOT READY**  
**Evidence-collection (two honest blind personas, recovered): PASS**

---

## Part 1 — Initial run (cache-caused launch infrastructure; NON-AUTHORITATIVE for UX)

Preserved for history in `docs/qa/PLAYER_EXPERIENCE_PASS_01.md` (pre-recovery sections) and:

- `tmp/px_pass_01/evidence/A|B/00_main_menu.png` (blank gray)  
- `tmp/px_pass_01/logs/godot_A_20260809_213251.log`, `godot_B_20260809_213349.log`  

**Classification:** missing project `.godot/` / class cache → script parse + failed autoloads → blank window.  
**Do not** use this layer to judge tutorial/objective/Neighbor UX.

---

## Part 2 — Environment-recovery re-run (AUTHORITATIVE Phase A baseline)

Fresh isolated profiles; same driver; opened screenshots + raw logs.

### Commands

```text
py -3 tmp/px_pass_01/driver/launch_and_capture.py --persona A_recovery --wait 12 --shot tmp/px_pass_01/evidence/A_recovery/00_main_menu.png --pid-file tmp/px_pass_01/logs/pid_A_recovery.txt

# New Game: click client ~960,500 (Enter did not fire menu)
# Look via click-drag relative mouse; move/interact via scancode WASD/E

py -3 tmp/px_pass_01/driver/launch_and_capture.py --persona B_recovery --wait 12 --shot tmp/px_pass_01/evidence/B_recovery/00_main_menu.png --pid-file tmp/px_pass_01/logs/pid_B_recovery.txt

# Persona B: click «Новая игра» only; idle; no assumed WASD/mouse-look
```

Underlying:

```text
Godot_v4.7.1-stable_win64_console.exe --path <project> --resolution 1920x1080 --windowed
APPDATA=tmp/px_pass_01/userdata_A_recovery | userdata_B_recovery
```

### Engine logs (recovery)

- `tmp/px_pass_01/logs/godot_A_recovery_20260809_213732.log`  
- `tmp/px_pass_01/logs/godot_B_recovery_20260809_214418.log`  

Observed: module-ready lines → `Boot -> title menu (World deferred)` → after New Game `Player ready`. **No** parse/autoload storm.

### Criteria (recovery baseline)

| Criterion | Status | Evidence |
|---|---|---|
| Isolated recovery profiles | **PASS** | `userdata_A_recovery`, `userdata_B_recovery` + `commands_*_recovery.txt` |
| 1920×1080 windowed, UI 100% intent | **PASS** | client ~1920×1061 captures |
| Title → «Новая игра» proven | **PASS** | opened `A_recovery/00_main_menu.png`, `B_recovery/00_main_menu.png` |
| Raw Godot log distinct from journal | **PASS** | recovery logs above |
| Persona A natural progress toward Neighbor | **FAIL** | explored apartment; fridge `[E]`; city door story-locked; no Neighbor |
| Persona B taught-controls-only | **FAIL** | stuck at door spawn; no tutorial/prompt/goal |
| Neighbor / first prologue interaction | **FAIL** (not reached) | no `08_neighbor_*` / `09_*` |
| Spec shots `07_`–`10_` | **NOT RUN** | blocked before exit/Neighbor |
| Save/load on prologue | **NOT RUN** | route not reached |
| No production mutation | **PASS** | only `docs/qa/…`, `docs/agent/qa/PE01_BLIND_A_B_QA.md`, `tmp/px_pass_01/**` |

### Actual recovery player flow

**Persona A**

1. Main Menu visible (DATE FACTORY / Главное меню / Новая игра).  
2. Click New Game → FPS apartment, face into door; resource HUD; debug `mode=GAMEPLAY target=`.  
3. No movement tutorial; no ЦЕЛЬ UI.  
4. Drag-look + WASD → kitchen/bed/window.  
5. Fridge: **ХОЛОДИЛЬНИК** + **`[E] Осмотреть`** (debug `FlavorFridge`). E does not reveal Neighbor/story next step.  
6. Door: **`[E] Недоступно — Пока недоступно по сюжету`** (debug `ToCity`).  
7. Stuck ~1:40 — no Neighbor, no alternate goal.

**Persona B**

1. Main Menu → click Новая игра.  
2. Face door; no taught WASD/mouse; no `[E]` prompt at spawn gaze; no objective.  
3. Idle + one E without prompt → no change.  
4. Stuck ~0:25.

### Player inferences (recovery)

| Persona | Inferences from pixels |
|---|---|
| A | “Start via Новая игра” → “maybe open door” → “this is an apartment; fridge can be inspected” → “exit is story-locked; I still don’t know the real goal / where a person is” |
| B | “Click Новая игра” → “I don’t know how to move or what to do; nothing teaches me” |

### Screenshots (opened)

**A recovery**

| File | Actual content |
|---|---|
| `evidence/A_recovery/00_main_menu.png` | Real main menu; Новая игра focused |
| `evidence/A_recovery/01_new_game_first_frame.png` | Face-to-door spawn + HUD + debug |
| `evidence/A_recovery/03_first_movement.png` | Kitchen/bed/window after look |
| `evidence/A_recovery/04_first_interaction_prompt.png` | `[E] Осмотреть` on fridge |
| `evidence/A_recovery/06_exit_approach.png` / `stuck_01_40_no_neighbor_or_goal.png` | Door locked by story; prompt visible |

**B recovery**

| File | Actual content |
|---|---|
| `evidence/B_recovery/00_main_menu.png` | Main menu |
| `evidence/B_recovery/01_new_game_first_frame.png` | Door spawn; no tutorial |
| `evidence/B_recovery/stuck_00_25_no_taught_controls_or_goal.png` | Still at door; no prompts |

### BLIND RUN A — RECOVERY

```text
furthest natural progress: apartment explore + fridge inspect + see story-locked city exit
time until first stuck: ~01:40
first stuck reason: no Neighbor; exit story-locked; no objective UI
Blockers:
  - Neighbor/prologue not naturally reachable
  - City exit unavailable by story with no alternate goal
Majors:
  - No current objective UI
  - No controls tutorial on fresh New Game
  - Poor spawn first view (face into door)
  - Debug overlay / internal target names visible
```

### BLIND RUN B — RECOVERY

```text
furthest natural progress: New Game → idle at door
time until first stuck: ~00:25
first stuck reason: controls/goal not taught; no interaction prompt at spawn
Blockers:
  - Cannot proceed without untaught FPS assumptions
Majors:
  - Tutorial absent
  - No objective UI
```

---

## Changed files

- `docs/qa/PLAYER_EXPERIENCE_PASS_01.md` — appended dated recovery section (original A/B kept)  
- `docs/agent/qa/PE01_BLIND_A_B_QA.md` — this update  
- `tmp/px_pass_01/evidence/{A_recovery,B_recovery}/**`, `logs/godot_*_recovery_*.log`, `userdata_*_recovery/`, driver reused  

---

## Limitations

- Cursor desktop computer-use unavailable; Win32/PIL driver used.  
- Client height ~1061 under 1920×1080 request.  
- Menu **Enter** did not activate New Game; mouse click did.  
- Relative look more reliable via click-drag than free relative-only in this driver session.  
- Initial blank-gray A/B retained as infra evidence only.

---

## Unmet criteria (authoritative recovery)

- Reach Neighbor / start intended first prologue interaction  
- Persistent player-facing current objective  
- Controls tutorial that Persona B can follow  
- Spec screenshots `07_`–`10_`  
- Time-to-goal ≤15s / Neighbor progress ≤120s  

---

## Overall status

**FAIL** — authoritative recovered baseline: first prologue route **not** reached.

## Blocking issues

1. **(Recovery / gameplay)** Neighbor / prologue interaction not found by natural apartment play; city exit explicitly story-locked without a replacement goal.  
2. **(Recovery / Persona B)** No visible control teaching → stuck at spawn.  
3. **(Initial only / infra)** Missing `.godot` cache caused blank launch — **fixed for recovery; not the UX baseline.**

## Non-blocking issues

1. Debug `mode=GAMEPLAY target=…` overlay (and internal names like FlavorFridge / ToCity).  
2. Title menu keyboard Activate unreliable vs mouse click.  
3. Easy to clip camera into dark near-wall views while exploring.  
4. Fridge inspect is a flavor dead-end for prologue purpose.

## Evidence

- Journal: `docs/qa/PLAYER_EXPERIENCE_PASS_01.md` (original + **ENVIRONMENT-RECOVERY RE-RUN**)  
- Screenshots: `tmp/px_pass_01/evidence/A_recovery/`, `B_recovery/`  
- Logs: `tmp/px_pass_01/logs/godot_*_recovery_*.log`  
- Commands: `tmp/px_pass_01/logs/commands_*_recovery.txt`  

## Reproduction steps

1. Ensure project `.godot` cache present.  
2. Launch with isolated `APPDATA=tmp/px_pass_01/userdata_A_recovery` and `--resolution 1920x1080 --windowed`.  
3. Confirm Main Menu → click «Новая игра».  
4. Explore without source knowledge; attempt to find a person / first story action.  
5. Observe story-locked exit and absence of objective/tutorial (Persona B: do not move without taught controls).  

---

## PASS/FAIL recommendation

| Layer | Verdict |
|---|---|
| Evidence collection (recovery A+B) | **PASS** |
| Initial blank launch (cache) | Infra FAIL — superseded |
| Authoritative Phase A first-time route / onboarding | **FAIL (NOT READY)** |

---

## Follow-on: Phase C/D (AFTER FIX)

Authoritative post-fix source-blind verification is recorded separately:

- Report: [`docs/agent/qa/PE01_BLIND_C_D_QA.md`](PE01_BLIND_C_D_QA.md) → **PASS**
- Journal append: `docs/qa/PLAYER_EXPERIENCE_PASS_01.md` → section **PHASE C/D**
- Evidence: `tmp/px_pass_01/evidence/C/`, `tmp/px_pass_01/evidence/D/`
- Logs: `tmp/px_pass_01/logs/godot_C_20260809_220623.log`, `godot_D_20260809_222512.log`

This A/B report remains the Phase A / recovery historical record and is not rewritten.

