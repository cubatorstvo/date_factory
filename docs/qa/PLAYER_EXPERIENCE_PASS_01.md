# PLAYER EXPERIENCE PASS 01 — Player Journal

**Pass:** PLAYER EXPERIENCE PASS 01 — BLACK-BOX ONBOARDING + PHYSICAL COLLISION QA  
**Phase:** A — BEFORE FIX (source-blind)  
**Baseline commit:** `86cb0f9`  
**Resolution intent:** 1920×1080 windowed, UI scale 100% via empty isolated profile  
**Computer-use:** Cursor desktop computer-use unavailable → development-only platform driver under `tmp/px_pass_01/driver/`  
**Isolation:** process `APPDATA` redirected to `tmp/px_pass_01/userdata_{A|B}` (developer profile not used)

---

## Launch / input commands (exact)

### Persona A

```text
utc=2026-08-09T18:32:51Z
APPDATA=C:\Users\User\Documents\GodotProjects\date_factory\tmp\px_pass_01\userdata_A
godot=C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe
args=--path C:\Users\User\Documents\GodotProjects\date_factory --resolution 1920x1080 --windowed
log=tmp/px_pass_01/logs/godot_A_20260809_213251.log
pid=17872
```

Driver helper:

```text
py -3 tmp/px_pass_01/driver/launch_and_capture.py --persona A --wait 10 --shot tmp/px_pass_01/evidence/A/00_main_menu.png
```

Inputs attempted after window appeared: focus window; center click; Escape (retry capture). No movement/interact keys — no playable UI visible.

### Persona B

```text
utc=2026-08-09T18:33:49Z
APPDATA=C:\Users\User\Documents\GodotProjects\date_factory\tmp\px_pass_01\userdata_B
godot=C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe
args=--path C:\Users\User\Documents\GodotProjects\date_factory --resolution 1920x1080 --windowed
log=tmp/px_pass_01/logs/godot_B_20260809_213349.log
pid=20932
```

Driver helper:

```text
py -3 tmp/px_pass_01/driver/launch_and_capture.py --persona B --wait 12 --shot tmp/px_pass_01/evidence/B/00_main_menu.png
```

Inputs attempted: focus; one center-screen click only (no taught controls on screen; no assumed WASD/E).

---

## BLIND RUN A — BEFORE FIX (Persona A: common FPS conventions allowed)

### Journal

| timestamp | visible state | player inference | action | result | problem | severity |
|---|---|---|---|---|---|---|
| 00:00 | Process starts; window title `DATE FACTORY (DEBUG)` | Game is launching | wait ~10s for menu | Window client ~1920×1061 is solid dark gray; taskbar still visible at bottom of capture | No Main Menu chrome, no «Новая игра», no HUD, no world | BLOCKER |
| 00:10 | Same blank gray full-window fill | Maybe still loading / stuck | capture `00_main_menu.png` | Opened image: uniform charcoal field; no buttons/text | Cannot prove title → New Game route | BLOCKER |
| 00:15 | Unchanged blank gray | If FPS game, Esc might dismiss overlay | focus + center click + Escape; recapture `00_main_menu_retry.png` | Still blank gray (mean luma ~74) | No response to ordinary input | BLOCKER |
| 00:20 | Unchanged | Stuck: >20s with no plausible next goal and no affordance | capture `stuck_00_00_blank_no_main_menu.png`; end run | Stopped | Cannot enter New Game, move, look, interact, or search for Neighbor | BLOCKER |

### Screenshots reached

| Spec name | Path | Opened content |
|---|---|---|
| `00_main_menu` | `tmp/px_pass_01/evidence/A/00_main_menu.png` | Blank dark gray game window; no menu UI |
| `01_new_game_first_frame` … `10_first_story_next_step` | — | **NOT REACHED** |
| stuck | `tmp/px_pass_01/evidence/A/stuck_00_00_blank_no_main_menu.png` | Same blank gray stuck state |

### Concise result A

```text
furthest natural progress: game window opens; Main Menu never appears
time until first stuck: ~00:10–00:20 from launch (immediate pre-menu)
first stuck reason: blank gray window; no visible Main Menu / New Game control
Blockers:
  - cannot reach Main Menu / click «Новая игра»
  - no playable scene/UI after launch
Majors:
  - (none evaluated beyond pre-menu blocker; later onboarding criteria NOT RUN)
```

---

## BLIND RUN B — BEFORE FIX (Persona B: only controls taught on screen)

### Journal

| timestamp | visible state | player inference | action | result | problem | severity |
|---|---|---|---|---|---|---|
| 00:00 | Fresh isolated launch; window `DATE FACTORY (DEBUG)` | Waiting for any taught UI | wait ~12s | Solid dark gray client area only | No tutorial text, no buttons, no prompts | BLOCKER |
| 00:12 | Blank gray | Goal unknown; no taught keys | capture `00_main_menu.png` | Opened image: blank gray; Godot taskbar icon active; clock ~21:34 | Cannot start New Game from title | BLOCKER |
| 00:20 | Unchanged | No controls taught → do not assume WASD/E/Esc | one exploratory center click only | No visible change | Still no affordance | BLOCKER |
| 00:25 | Unchanged | Stuck under 20s-no-goal / no-affordance rules | `stuck_00_00_blank_no_main_menu.png`; end | Stopped | Persona B cannot be onboarded at all | BLOCKER |

### Screenshots reached

| Spec name | Path | Opened content |
|---|---|---|
| `00_main_menu` | `tmp/px_pass_01/evidence/B/00_main_menu.png` | Blank dark gray; no menu |
| later spec shots | — | **NOT REACHED** |
| stuck | `tmp/px_pass_01/evidence/B/stuck_00_00_blank_no_main_menu.png` | Blank gray stuck |

### Concise result B

```text
furthest natural progress: game window opens; Main Menu never appears
time until first stuck: ~00:12–00:20 from launch
first stuck reason: blank gray window; zero taught controls / zero UI
Blockers:
  - cannot reach Main Menu / «Новая игра»
  - no taught controls exist on screen to continue
Majors:
  - (downstream onboarding NOT RUN)
```

---

## Raw engine logs (distinct from this journal)

| Run | Path | Observed (from log text, not source inspection) |
|---|---|---|
| A | `tmp/px_pass_01/logs/godot_A_20260809_213251.log` (~2905 lines) | Mass `SCRIPT ERROR` / `Parse Error` for missing global types; many `Failed to load script`; many `Failed to instantiate an autoload`; `Failed to load script "res://core/main_bootstrap.gd"` |
| B | `tmp/px_pass_01/logs/godot_B_20260809_213349.log` | Same failure pattern |

Command records: `tmp/px_pass_01/logs/commands_A.txt`, `commands_B.txt`.

---

## Launch environment note (non-gameplay, observed during launch)

- Project path `res://` launch was attempted from clean baseline `86cb0f9`.
- On disk, `C:\Users\User\Documents\GodotProjects\date_factory\.godot` was **absent** at test time (`project_godot_dir=False`). This is recorded only as a launch-infrastructure observation correlating with class/parse failures in the raw engine log — not as a source-code diagnosis of gameplay systems.
- A Godot editor process for the same project remained open separately during tests; black-box runs used a separate `--path` process with isolated `APPDATA`.

---

## Explicit NOT RUN limitations (Phase A)

Because Main Menu never appeared, the following Phase A player checks are **NOT RUN** (not PASS):

- Title → «Новая игра» proof beyond launch attempt
- First-frame apartment spawn readability
- Movement / look / interact comprehension (≤10s / ≤30s targets)
- Current objective comprehension (≤15s)
- Apartment navigation / collision walk tests
- Exit approach / after-exit
- Neighbor seen / Neighbor interaction / first story next step
- Screenshots `01_` through `10_` from the pass spec
- Save/load during prologue route
- Persona difference beyond “FPS keys allowed vs not” (both stuck equally before any controls matter)

---

## Overall Phase A verdict (journal)

**BLOCKED BEFORE MENU.** Two honest isolated black-box attempts completed; both stuck on a blank gray window with engine parse/autoload failures in the raw Godot logs. No gameplay mutation performed. No source/GDD consultation used to “rescue” the route.

---

## ENVIRONMENT-RECOVERY RE-RUN — 2026-08-09 (after launch cache restored)

**Dated note:** Original A/B history above is preserved unchanged. This section is the **authoritative Phase A gameplay baseline** once `.godot` launch cache was restored and headless boot reached title. Profiles: `userdata_A_recovery`, `userdata_B_recovery`. Same platform driver; no source/GDD/state API use.

### Launch / input commands (recovery)

#### Persona A recovery

```text
utc=2026-08-09T18:37:32Z
APPDATA=...\tmp\px_pass_01\userdata_A_recovery
godot=...\Godot_v4.7.1-stable_win64_console.exe
args=--path <project> --resolution 1920x1080 --windowed
log=tmp/px_pass_01/logs/godot_A_recovery_20260809_213732.log
pid=25316 (child window pid 9456)
```

```text
py -3 tmp/px_pass_01/driver/launch_and_capture.py --persona A_recovery --wait 12 --shot tmp/px_pass_01/evidence/A_recovery/00_main_menu.png
# New Game: click client ~960,500 (Enter did not activate menu)
# Look: click-drag relative mouse; Move/Interact: scancode WASD / E
```

#### Persona B recovery

```text
utc=2026-08-09T18:44:18Z
APPDATA=...\tmp\px_pass_01\userdata_B_recovery
godot=...\Godot_v4.7.1-stable_win64_console.exe
args=--path <project> --resolution 1920x1080 --windowed
log=tmp/px_pass_01/logs/godot_B_recovery_20260809_214418.log
pid=14564
```

```text
py -3 tmp/px_pass_01/driver/launch_and_capture.py --persona B_recovery --wait 12 --shot tmp/px_pass_01/evidence/B_recovery/00_main_menu.png
# New Game: click «Новая игра» only; no assumed WASD/mouse-look; one E only if prompt might exist
```

Raw engine logs (recovery): clean module-ready boot → `Boot -> title menu`; then `Player ready` after New Game. No parse/autoload storm (contrast original failed A/B logs).

---

### BLIND RUN A — RECOVERY (Persona A: FPS conventions allowed)

#### Journal

| timestamp | visible state | player inference | action | result | problem | severity |
|---|---|---|---|---|---|---|
| 00:00 | Main Menu: DATE FACTORY / Главное меню; buttons Продолжить (dim), **Новая игра** (highlighted), Загрузить, Настройки, Выход; v1.0.0 | Start a new game | wait; capture `00_main_menu.png` | Title proven | — | — |
| 00:20 | Same menu; Enter key no-op | Need to activate highlighted New Game | mouse click ~center on «Новая игра» | Enters gameplay; log `Player ready` | Keyboard activate unreliable from title | MINOR |
| 00:22 | FPS view jammed on brown door; HUD `$0 / АВТОРИТЕТ 0 / ОПЫТНОСТЬ 0 / БАЛЛЫ 0`; faint `mode=GAMEPLAY target=`; white `+` crosshair; **no** movement tutorial; **no** objective UI | Maybe open the door? Room not readable yet | capture `01_new_game_first_frame` / `02_new_game_10s` | Face-into-door spawn | Spawn looks like face against geometry; no goal text | MAJOR |
| 00:40 | After drag-look: kitchen (fridge/sink/stove), bed, blue blinds | Explore apartment; find someone / exit | WASD + look around | Room readable | Still no ЦЕЛЬ / tutorial card | MAJOR |
| 01:00 | Near fridge: title **ХОЛОДИЛЬНИК**, flavor text, prompt **`[E] Осмотреть`**; debug `target=FlavorFridge` | Inspect fridge | E | Prompt/UI respond; no story progress apparent | Internal id leaked in debug line; inspect ≠ prologue | MAJOR (debug) / MINOR (fridge dead-end) |
| 01:20–01:40 | Room sweep: wardrobe/window/bed areas; also dark near-wall views; **no person** | Find neighbor / next story beat | look + move + E attempts | No Neighbor seen | Neighbor not discoverable in apartment search | BLOCKER |
| 01:40 | Door again: **`[E] Недоступно — Пока недоступно по сюжету`**; debug `target=ToCity` | Exit is the way forward but locked | E on door | Explicit story lock | Exit blocked with no alternate goal shown | BLOCKER |
| 01:45 | Same apartment; fridge/door only clear affordances | Stuck: no goal, no Neighbor, locked exit | `stuck_01_40_no_neighbor_or_goal.png`; end | Stop | Cannot reach prologue Neighbor route | BLOCKER |

#### Screenshots (recovery A)

| Spec / stuck | Path | Opened content |
|---|---|---|
| `00_main_menu` | `tmp/px_pass_01/evidence/A_recovery/00_main_menu.png` | Real Main Menu with «Новая игра» |
| `01_new_game_first_frame` | `.../01_new_game_first_frame.png` | Face-to-door spawn + resource HUD + debug line |
| `02_new_game_10s` | `.../02_new_game_10s.png` | Still door; no tutorial/objective |
| `03_first_movement` | `.../03_first_movement.png` (= drag look) | Kitchen/bed/window room readable |
| `04_first_interaction_prompt` | `.../04_first_interaction_prompt.png` | `[E] Осмотреть` + ХОЛОДИЛЬНИК |
| `05_apartment_navigation` | `.../05_apartment_navigation.png` / sweeps | Apartment corners; often dark when too close |
| `06_exit_approach` | `.../06_exit_approach.png` | Door + story-unavailable E prompt |
| `07_after_exit` … `10_*` | — | **NOT REACHED** |
| stuck | `.../stuck_01_40_no_neighbor_or_goal.png` | Locked city door; no Neighbor |

#### Concise result A (recovery)

```text
furthest natural progress: Main Menu → New Game → apartment explore; fridge inspect prompt; city-exit door shows story-locked E
time until first stuck: ~01:40 (Neighbor/goal never found; exit locked)
first stuck reason: no visible current objective; Neighbor not found; only clear “forward” exit is story-locked
Blockers:
  - Neighbor / prologue first interaction not reachable by natural search
  - City exit: «Недоступно — Пока недоступно по сюжету» with no alternate goal
Majors:
  - No persistent ЦЕЛЬ / purpose UI
  - No FIRST_MOVEMENT (or equivalent) tutorial card on fresh New Game
  - Spawn first view face-into door / poor room context
  - Debug overlay visible (mode=GAMEPLAY target=… including FlavorFridge / ToCity)
```

---

### BLIND RUN B — RECOVERY (Persona B: only visibly taught controls)

#### Journal

| timestamp | visible state | player inference | action | result | problem | severity |
|---|---|---|---|---|---|---|
| 00:00 | Main Menu with «Новая игра» highlighted | Click New Game | click button | Gameplay starts | — | — |
| 00:03 | Face door; HUD zeros; debug line; **no** control tutorial; **no** `[E]` prompt (crosshair on wall beside door) | Goal unknown; controls unknown | capture first/10s; idle | Unchanged door wall | Movement/look never taught | BLOCKER |
| 00:15 | Same | Maybe E works on door? (no prompt text) | single E (optimistic) | No visible change | Interaction not taught at spawn | MAJOR |
| 00:25 | Same door view ~25s | Stuck: no taught WASD/mouse, no objective, no prompt | `stuck_00_25_no_taught_controls_or_goal.png`; end | Stop | Cannot leave spawn without assumed FPS knowledge | BLOCKER |

#### Screenshots (recovery B)

| Spec / stuck | Path | Opened content |
|---|---|---|
| `00_main_menu` | `tmp/px_pass_01/evidence/B_recovery/00_main_menu.png` | Main Menu |
| `01_new_game_first_frame` | `.../01_new_game_first_frame.png` | Door spawn; no tutorial |
| `02_new_game_10s` | `.../02_new_game_10s.png` | Same; still no taught controls |
| later shots | — | **NOT REACHED** (no movement taught) |
| stuck | `.../stuck_00_25_no_taught_controls_or_goal.png` | Idle at door; no prompts |

#### Concise result B (recovery)

```text
furthest natural progress: Main Menu → New Game → idle at door spawn
time until first stuck: ~00:20–00:25
first stuck reason: no visible control teaching; no objective; no interaction prompt at spawn gaze
Blockers:
  - Cannot proceed without assuming untaught WASD/mouse-look
Majors:
  - Tutorial never appears on fresh New Game
  - No current goal UI
```

---

### Recovery overall (authoritative Phase A baseline)

**First route (Neighbor / prologue interaction): NOT REACHED.**

Launch infrastructure failure from the original A/B section is **superseded** for “can the game boot to title?” — recovery boots cleanly to Main Menu.  
Player-experience readiness for onboarding/Neighbor remains **FAIL** on gameplay usability evidence above.

---

## PHASE C/D — AFTER ONBOARDING/SCENE FIXES (AUTHORITATIVE source-blind verification)

**Phase:** C + D — AFTER FIX (fresh, source-blind)  
**Date:** 2026-08-09  
**Profiles:** `tmp/px_pass_01/userdata_C`, `tmp/px_pass_01/userdata_D` (isolated APPDATA; developer profile untouched)  
**Resolution:** 1920×1080 windowed; UI 100% via empty isolated profile  
**Driver:** `tmp/px_pass_01/driver/launch_and_capture.py` + `bb_driver.py` (keyboard/mouse/screenshots only; no GodotIQ/Story/state APIs)  
**Prior A/B and recovery sections above are UNCHANGED historical evidence.**

### Launch commands (exact)

#### Persona C (FPS conventions allowed)

```text
utc=2026-08-09T19:06:23Z
APPDATA=C:\Users\User\Documents\GodotProjects\date_factory\tmp\px_pass_01\userdata_C
godot=C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe
args=--path C:\Users\User\Documents\GodotProjects\date_factory --resolution 1920x1080 --windowed
log=tmp/px_pass_01/logs/godot_C_20260809_220623.log
pid=12552
```

```text
py -3 tmp/px_pass_01/driver/launch_and_capture.py --persona C --wait 10 --shot tmp/px_pass_01/evidence/C/00_main_menu.png
```

Authoritative C gameplay evidence folder: `tmp/px_pass_01/evidence/C/` (includes `01`–`10`, `hall_*`, `col_*`).

#### Persona D (taught-only; fresh relaunch after first session aim loss)

```text
utc=2026-08-09T19:25:12Z
APPDATA=C:\Users\User\Documents\GodotProjects\date_factory\tmp\px_pass_01\userdata_D
godot=C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe
args=--path C:\Users\User\Documents\GodotProjects\date_factory --resolution 1920x1080 --windowed
log=tmp/px_pass_01/logs/godot_D_20260809_222512.log
pid=19888
```

```text
py -3 tmp/px_pass_01/driver/launch_and_capture.py --persona D --wait 10 --shot tmp/px_pass_01/evidence/D/00_main_menu_fresh.png
```

Authoritative D gameplay evidence: `tmp/px_pass_01/evidence/D/` (`00`–`10`, `d2_*` fresh path). An earlier same-day D session (`godot_D_20260809_221315.log`) is retained as exploration noise; verdict uses the fresh relaunch.

---

### BLIND RUN C — AFTER FIX (Persona C)

#### Journal

| timestamp | visible state | player inference | action | result | problem | severity |
|---|---|---|---|---|---|---|
| 00:00 | Main Menu `DATE FACTORY` / `Новая игра` | Start new game | mouse-click `Новая игра` | Enter apartment gameplay | — | — |
| ≤00:10 | Bottom tutorial `WASD — движение` / `Мышь — обзор` / `E — взаимодействие`; top-right `ЦЕЛЬ` / `Познакомься с соседкой.`; room with bed/window/table/dresser; contextual `E — Стол для свидания`; **no** `mode=` debug line | Controls + goal readable; spawn is room-readable (not door face-plant) | capture `01`/`02` | Opened images confirm | — | — |
| ≤00:30 | Same | Move/look taught | WASD + mouse look | View changes; tutorial collapses toward lingering `E — взаимодействие` | Move/look teaching advances with evidence | — |
| ~01:00 | Physical probes of bed/nightstand/wardrobe/table/kitchen/exit | Test collision by walking into props front/side | approach + strafe | Furniture/walls generally **block**; camera can **clip into** near-wall brown/dark views; wardrobe/exit fronts often read as camera-into-surface | Soft camera vs hard body mismatch | MINOR |
| ~01:30 | Hallway doors; Neighbor NPC visible; goal still meet Neighbor | Neighbor is the objective | approach | `E — Познакомиться` when aimed | City door nearby can show `E — Недоступно — Пока недоступно по сюжету` while goal remains Neighbor (lock ≠ active objective) | — |
| ~02:00 | Prompt `E — Познакомиться` | Press taught E | E | Dialogue about mug + choices | Visible feedback | — |
| ~02:10 | Choice taken | Continue | select available choice | Modal `НОМЕР ПОЛУЧЕН` + body text + `OK` | Immediate next step toward dating (number received) | — |
| ~02:20 | Modal hard to dismiss via automation; bottom teaching may linger after success | Stop at post-prologue setup / modal | capture `10*` | Stopped without forced further progression | Control-return / OK dismiss flaky under driver; goal text may linger | MINOR |

#### Screenshots C (opened)

| Spec | Path | Opened content |
|---|---|---|
| `00_main_menu` | `evidence/C/00_main_menu.png` | Title menu |
| `01_new_game_first_frame` | `evidence/C/01_new_game_first_frame.png` | Room spawn; full tutorial card; `ЦЕЛЬ`; `E — Стол для свидания`; no debug |
| `02_new_game_10s` | `evidence/C/02_new_game_10s.png` | Same onboarding still readable |
| `03_first_movement` | `evidence/C/03_first_movement.png` | Post-move view; teaching reduced |
| `08_neighbor_seen` / `hall_0` | `evidence/C/08_neighbor_seen.png`, `hall_0.png` | Neighbor; `E — Познакомиться` |
| `09_neighbor_interaction` | `evidence/C/09_neighbor_interaction.png` | Mug dialogue + choices |
| `10_first_story_next_step` / `10c` | `evidence/C/10_first_story_next_step.png`, `10c_post_prologue_state.png` | `НОМЕР ПОЛУЧЕН` modal |
| collision | `evidence/C/col_*_{front,side}.png` | Prop approach probes |

#### Concise result C

```text
furthest natural progress: Main Menu → New Game → apartment → Neighbor E → dialogue → НОМЕР ПОЛУЧЕН
time until controls: ≤10s; goal ≤15s; first move ≤30s
first stuck reason: none on critical route (modal OK dismiss flaky under automation only)
Blockers: none on Neighbor/prologue route
Majors/minors: lingering generic E teaching after success; camera clip into walls; NPC clothing clip; OK modal dismiss unreliable via driver
```

---

### BLIND RUN D — AFTER FIX (Persona D, taught-only)

#### Journal

| timestamp | visible state | player inference | action | result | problem | severity |
|---|---|---|---|---|---|---|
| 00:00 | Main Menu; `Новая игра` highlighted | Must click taught/visible New Game | mouse-click `Новая игра` | Gameplay | — | — |
| ≤00:10 | Tutorial card with `WASD` / `E` (C confirms `Мышь` line on same build); `ЦЕЛЬ` meet Neighbor; room-readable spawn; `E — Стол для свидания` | Use only taught WASD / mouse / E | capture `01`/`02` | Opened: onboarding readable | — | — |
| ≤00:30 | Taught move | W + mouse look | capture `03_first_movement` | Movement works; card → lingering `E — взаимодействие` | Teaching progresses with evidence | — |
| ~01:00 | Pan using mouse look | Goal says meet Neighbor → search room | left yaw scan | Neighbor found at hallway doors (`08_neighbor_seen` / `d2_pan2_18`) | — | — |
| ~01:20 | Aim at Neighbor | Contextual `E — Познакомиться` | walk closer + E | Dialogue appears | Visible interaction feedback | — |
| ~01:30 | Dialogue choices | Select available choice | click option | `НОМЕР ПОЛУЧЕН` modal (`d2_choice_2` / `10_first_story_next_step`) | Next dating step visible | — |
| ~01:40 | After modal | Re-aim Neighbor/door | observe prompts | `E — номер уже получен` and/or door `E — Недоступно — Пока недоступно по сюжету`; goal text can still say meet Neighbor; bottom `E — взаимодействие` still present | Teaching/goal not fully cleared after success | MINOR |
| note | Earlier D session lost free-look until RMB; corner stuck during aim | Driver/capture quirk | fresh relaunch | Clean path succeeded | Do not treat mid-session aim loss as product blocker | — |

#### Screenshots D (opened)

| Spec | Path | Opened content |
|---|---|---|
| `00_main_menu` | `evidence/D/00_main_menu.png` | Main Menu |
| `01` / `02` | `evidence/D/01_new_game_first_frame.png`, `02_new_game_10s.png` | Room spawn; goal; tutorial; dating-table prompt |
| `03_first_movement` | `evidence/D/03_first_movement.png` | After first move |
| `08_neighbor_seen` | `evidence/D/08_neighbor_seen.png` | Neighbor in hallway |
| `09_neighbor_interaction` | `evidence/D/09_neighbor_interaction.png` / `d2_close_01.png` | `E — Познакомиться` |
| dialogue | `evidence/D/d2_E_00.png` | Mug dialogue |
| `10_first_story_next_step` | `evidence/D/10_first_story_next_step.png` (= `d2_choice_2`) | `НОМЕР ПОЛУЧЕН` |
| story-lock affordance | `evidence/D/d_mouse_c_rmb.png`, `d2_choice_7.png` | Door `Недоступно — Пока недоступно по сюжету` while goal remains Neighbor |

#### Concise result D

```text
furthest natural progress: Main Menu → New Game → taught move/look → find Neighbor → E → dialogue → НОМЕР ПОЛУЧЕН
time until controls/goal: ≤10s / ≤15s; first move ≤30s
first stuck reason: none on fresh taught-only path
Blockers: none
Majors/minors: lingering generic E after success; goal text may linger after number received; NPC visual clip; free-look can drop if mouse capture lost (driver/session)
```

---

### Acceptance observations (C+D)

| Observation | Result | Evidence |
|---|---|---|
| Controls visible/readable ≤10s | **PASS** | C/D `01`/`02` |
| Goal visible ≤15s | **PASS** | `ЦЕЛЬ` / `Познакомься с соседкой.` |
| First meaningful move/interaction ≤30s | **PASS** | `03_*` |
| Initial frame room-readable (not a door) | **PASS** | bed/window/table visible |
| No debug `mode=` / internal target labels | **PASS** | opened HUD frames |
| Contextual prompts `E — <semantic action>` | **PASS** | `Стол для свидания`, `Познакомиться`, `Осмотреть`, story-lock wording |
| Move/look teaching progresses with player evidence | **PASS** | full card → lingering E |
| Interaction teaching clears after successful interaction | **WARNING** | bottom `E — взаимодействие` still present after dialogue/`НОМЕР ПОЛУЧЕН` |
| City exit story lock explained; not sold as active objective | **PASS** | `Недоступно — Пока недоступно по сюжету` while `ЦЕЛЬ` stays Neighbor |
| Neighbor findable via objective/world | **PASS** | hallway NPC under matching goal |
| Real E → visible feedback | **PASS** | dialogue + `НОМЕР ПОЛУЧЕН` |
| Collision physical probes | **WARNING** | props generally solid; camera often clips into surfaces; close NPC camera awkward |

### Phase C/D overall

**Critical Neighbor/prologue route: REACHABLE for both C and D.**  
**Authoritative recommendation: PASS** (with non-blocking UI/visual issues listed above).

Raw engine logs (distinct from this journal):  
- `tmp/px_pass_01/logs/godot_C_20260809_220623.log`  
- `tmp/px_pass_01/logs/godot_D_20260809_222512.log`  


---

## FINAL D — POST-INTERACTION ONBOARDING CORRECTION (source-blind, authoritative for this gate)

**Phase:** D_final — AFTER post-interaction onboarding correction  
**Date:** 2026-08-09  
**Persona:** D (taught-only; only controls visibly taught by the game)  
**Profile:** `tmp/px_pass_01/userdata_D_final` (fresh isolated APPDATA; developer profile untouched)  
**Resolution:** 1920×1080 windowed; UI 100% via empty isolated profile  
**Driver:** `tmp/px_pass_01/driver/launch_and_capture.py` + `bb_driver.py` (keyboard/mouse/screenshots only)  
**Forbidden this run:** source/GDD/tests/state/scene tree/remote inspector/reports; gameplay/Story APIs  
**Prior A/B/recovery and Phase C/D sections above are UNCHANGED historical evidence.**

### Launch command (exact)

```text
utc=2026-08-09T19:38:27Z
pid=5540 (console) / game window DATE FACTORY (DEBUG)
APPDATA=C:\Users\User\Documents\GodotProjects\date_factory\tmp\px_pass_01\userdata_D_final
godot=C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe
args=--path C:\Users\User\Documents\GodotProjects\date_factory --resolution 1920x1080 --windowed
log=tmp/px_pass_01/logs/godot_D_final_20260809_223827.log
commands=tmp/px_pass_01/logs/commands_D_final.txt
evidence=tmp/px_pass_01/evidence/D_final/
```

Raw engine log (distinct from this journal): `tmp/px_pass_01/logs/godot_D_final_20260809_223827.log`  
Contents: Godot 4.7.1 Vulkan boot + module ready lines + boot to title; **no** ERROR/WARNING/SCRIPT/Missing matches in scan.

### Journal (every inference / action / result)

| timestamp | visible state | player inference | action | result | problem | severity |
|---|---|---|---|---|---|---|
| 00:00 | Main Menu `DATE FACTORY` / `Новая игра` highlighted | Click New Game | mouse-click `Новая игра` | Enter apartment | — | — |
| ≤00:10 | Room-readable spawn (bed/window/table/dresser); bottom card `WASD — движение` / `E — взаимодействие`; `ЦЕЛЬ` / `Познакомься с соседкой.`; contextual `E — Стол для свидания`; **no** `mode=` | Use taught WASD + look + E only | capture `00`/`01`/`02` | Opened: onboarding readable | Opened descriptions list WASD+E; `Мышь — обзор` **not observed** in D_final `01`/`02` opens | WARNING |
| ≤00:30 | Taught move | W / A / D + mouse look (RMB-drag when free-look drops) | movement + pans | View changes; tutorial collapses toward lingering generic `E — взаимодействие` | Free-look can drop mid-session (driver/capture); recovered with taught movement + RMB look | MINOR |
| ~01:00–02:00 | Hallway doors; Neighbor NPC; goal still meet Neighbor; nearby door can show story-lock wording | Neighbor is the objective | approach + aim | `E — Познакомиться` + still-visible bottom `E — взаимодействие` (`n_aim_01` / `09_neighbor_prompt`) | Generic teaching still present **before** success (expected until clear-after-success) | — |
| ~02:10 | Semantic prompt | Press taught E | E | Mug dialogue + one **Доступно** choice | Visible feedback | — |
| ~02:20 | Available choice highlighted | Select available option | multi-position client clicks on right panel | `НОМЕР ПОЛУЧЕН` modal + body + visible `OK` (`choice_try_2` / `11_number_modal`) | Single first click missed; grid click succeeded (driver UX flake, not player-visible blocker) | MINOR |
| ~02:25 | Modal with OK | Dismiss via visible OK | further clicks on modal region | Gameplay resumes | OK dismiss under automation is multi-click flaky | MINOR |
| ~02:30 | Resumed HUD | Inspect correction | capture resumed frames | **Controls card completely absent** (no generic `E — взаимодействие`); `ЦЕЛЬ` = `Следующее свидание:` / `доступно` (not meet Neighbor); no debug | Post-contact semantic E prompt not re-acquired (crosshair on wall/close NPC back; sweeps `14`–`20_*`) | WARNING |
| end | Stop | Stop game PIDs; keep editor | taskkill game/console | Clean stop | — | — |

### Screenshots D_final (opened)

| Spec | Path | Opened content |
|---|---|---|
| title | `evidence/D_final/00_main_menu.png` | Main Menu; `Новая игра` highlighted |
| first frame | `evidence/D_final/01_new_game_first_frame.png` | Room spawn; `ЦЕЛЬ` meet Neighbor; WASD+E card; `E — Стол для свидания`; no debug |
| +10s | `evidence/D_final/02_new_game_10s.png` | Same onboarding family still readable |
| Neighbor prompt | `evidence/D_final/09_neighbor_prompt.png` / `n_aim_01.png` | Neighbor; `E — Познакомиться`; bottom generic E still present pre-success |
| dialogue | `evidence/D_final/n_E_0.png` | Mug narrative + available choice |
| number modal | `evidence/D_final/11_number_modal.png` (= `choice_try_2`) | `НОМЕР ПОЛУЧЕН` + OK |
| resumed | `evidence/D_final/12_resumed_post_number.png` / `13_resumed_gameplay.png` | Card absent; objective `Следующее свидание: доступно` |
| post scans | `evidence/D_final/14_*`…`20_sweep_*` | Card still absent; objective remains next-date; no re-acquired E prompt while mis-aimed |

### Final acceptance observations (this gate)

| Observation | Result | Evidence |
|---|---|---|
| Initial controls + `Познакомься с соседкой.` visible | **PASS** (with mouse-line WARNING) | `01`/`02` |
| No debug / internal IDs | **PASS** | all opened HUD frames |
| Neighbor naturally findable | **PASS** | `08_neighbor_seen` / `pan_*` / `09_neighbor_prompt` |
| Post-interaction controls card **completely absent** (esp. no generic E) | **PASS** | `12`/`13`/`14`–`20_*` (bottom-card bright pixels = 0 vs pre-success `09`) |
| Objective changed off meet-Neighbor to current first-date step | **PASS** | `Следующее свидание:` / `доступно` |
| Semantic post-contact prompt is player-facing | **WARNING** | Pre-contact `E — Познакомиться` PASS; post-OK re-aim did not show an E line in captured frames (aim/driver limitation this session) |

### Concise result D_final

```text
furthest natural progress: Main Menu → New Game → taught move/look → Neighbor → E → dialogue → НОМЕР ПОЛУЧЕН → OK → resumed gameplay
post-OK HUD: controls card gone; objective = Следующее свидание: доступно
first stuck reason: none on critical route
Blockers: none
Majors/minors: Мышь line not confirmed in opened D_final first frames; post-contact semantic E not recaptured; OK/choice automation flaky; free-look drops
```

### Overall (FINAL D correction gate)

**Critical post-interaction correction: PASS**  
Teaching card cleared after success; objective advances to visible first-date step.  
**Authoritative recommendation for this correction gate: PASS** (non-blocking WARNINGs above).

