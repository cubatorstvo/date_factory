# PE01-BLIND-C-D — Independent QA Report

**Task id:** PE01-BLIND-C-D  
**Role:** df-qa-worker (source-blind Phase C + D)  
**Date:** 2026-08-09  
**Gameplay mutation:** none (production onboarding/scene fixes already integrated before this verification)  
**GodotIQ / Story / state APIs used for play:** none  
**Source/GDD/fixture inspection:** none  

Companion history (unchanged): `docs/agent/qa/PE01_BLIND_A_B_QA.md`  
Player journal (C/D appended; A/B/recovery preserved): `docs/qa/PLAYER_EXPERIENCE_PASS_01.md`

---

## Summary

Fresh isolated profiles `userdata_C` and `userdata_D` were launched at 1920×1080 through the development-only platform driver. Both personas completed the real Main Menu → **Новая игра** → apartment onboarding → Neighbor discovery → real **E** interaction → dialogue → **`НОМЕР ПОЛУЧЕН`** next-step modal.

**Overall status: PASS**  
Critical first-route onboarding is player-reachable without source access. Non-blocking teaching/visual issues remain.

---

## Criteria

| Criterion | Status | Evidence | Reproduction |
|---|---|---|---|
| Controls visible/readable ≤10s | **PASS** | C/D `01`/`02` tutorial card | Fresh New Game; wait ≤10s |
| Goal visible ≤15s | **PASS** | `ЦЕЛЬ` / `Познакомься с соседкой.` | Same |
| First meaningful move/interaction ≤30s | **PASS** | `03_first_movement` | Use taught WASD/mouse |
| Initial frame room-readable (not door) | **PASS** | Bed/window/table/dresser in `01` | Open first gameplay frame |
| No debug `mode=` / internal target labels | **PASS** | Opened HUD frames vs recovery A debug overlay | Compare C/D `01` to A_recovery |
| Contextual `E — <semantic action>` | **PASS** | `E — Стол для свидания`, `E — Познакомиться`, story-lock wording | Aim table / Neighbor / city door |
| Move/look teaching progresses with evidence | **PASS** | Full card → lingering `E — взаимодействие` after move | Move once, recapture |
| Interaction teaching clears after success | **WARNING** | Bottom `E — взаимодействие` remains after dialogue / number | Complete Neighbor E; observe HUD |
| City exit story lock explained; not active objective | **PASS** | `E — Недоступно — Пока недоступно по сюжету` while goal stays Neighbor | Aim city/exit door near Neighbor |
| Neighbor findable via objective/world | **PASS** | Hallway NPC under matching goal | Follow `ЦЕЛЬ`, pan/search apartment |
| Real E → visible feedback | **PASS** | Mug dialogue; `НОМЕР ПОЛУЧЕН` | Aim Neighbor when prompt is `Познакомиться`, press E |
| Collision physical (listed props) | **WARNING** | C `col_*` probes: props generally solid; camera often clips into brown/near-wall; close NPC camera awkward | Walk front/side into bed/nightstand/wardrobe/table/kitchen/exit |
| Control return after interaction | **WARNING** | `НОМЕР ПОЛУЧЕН` OK dismiss flaky under driver; after dismiss gameplay resumes | Click OK after number modal |
| Save/load | **N/A** (stopped at post-prologue setup; not required for this route gate) | — | — |

---

## Persona results

### Persona C (FPS conventions OK) — **PASS**

- Route completed through `НОМЕР ПОЛУЧЕН`.
- Collision probes recorded under `tmp/px_pass_01/evidence/C/col_*`.
- Raw log: `tmp/px_pass_01/logs/godot_C_20260809_220623.log` (clean module boot; no parse/autoload failure).

### Persona D (taught-only) — **PASS**

- Fresh relaunch (`20260809_222512`) completed taught path end-to-end.
- Earlier same-day D session retained as noise (aim/capture loss); **not** used as FAIL evidence.
- Raw log: `tmp/px_pass_01/logs/godot_D_20260809_222512.log`.

---

## Blocking issues

None on the critical Main Menu → Neighbor → number-received route.

---

## Non-blocking issues

1. Generic bottom prompt `E — взаимодействие` often persists after move/look progress and after a successful Neighbor interaction.  
2. Goal text may still read `Познакомься с соседкой.` after `НОМЕР ПОЛУЧЕН` / `E — номер уже получен`.  
3. `НОМЕР ПОЛУЧЕН` OK button is easy to miss / hard to dismiss reliably via automated clicks (player can click OK).  
4. Camera frequently clips into walls/furniture; NPC clothing/placeholder clip visible.  
5. City door story-lock prompt can appear while standing next to Neighbor (explained correctly, but visually busy next to the real objective).

---

## Evidence

- Journal: `docs/qa/PLAYER_EXPERIENCE_PASS_01.md` → section **PHASE C/D**  
- Screenshots: `tmp/px_pass_01/evidence/C/`, `tmp/px_pass_01/evidence/D/`  
- Raw Godot stdout/stderr:  
  - `tmp/px_pass_01/logs/godot_C_20260809_220623.log`  
  - `tmp/px_pass_01/logs/godot_D_20260809_222512.log`  
- Commands: `tmp/px_pass_01/logs/commands_C.txt`, `commands_D.txt`  
- Driver: `tmp/px_pass_01/driver/`

### Opened-image highlights (authoritative)

- **C `01_new_game_first_frame`:** room spawn; `WASD`/`Мышь`/`E`; `ЦЕЛЬ`; `E — Стол для свидания`; no debug.  
- **C `09` / `10c`:** mug dialogue; `НОМЕР ПОЛУЧЕН`.  
- **D `01`/`02`:** same onboarding family; room-readable.  
- **D `d2_close_01` / `09`:** `E — Познакомиться`.  
- **D `d2_choice_2` / `10`:** `НОМЕР ПОЛУЧЕН`.  
- **D `d_mouse_c_rmb`:** door `Недоступно — Пока недоступно по сюжету` with Neighbor visible and goal still meet Neighbor.

---

## Reproduction steps

1. Keep project `.godot` cache valid.  
2. Launch with isolated `APPDATA=tmp/px_pass_01/userdata_C` (then D) and `--resolution 1920x1080 --windowed`.  
3. From Main Menu, mouse-click **Новая игра**.  
4. Confirm controls/goal within 10–15s; move with taught WASD/mouse.  
5. Search apartment for Neighbor under `ЦЕЛЬ`; aim until `E — Познакомиться`; press **E**.  
6. Take the available dialogue choice; observe `НОМЕР ПОЛУЧЕН`.  
7. Optionally aim city/exit door and confirm story-lock wording without replacing the goal.  
8. Stop at post-prologue setup; do not force later stages.

---

## Changed files (QA artifacts only)

- `docs/qa/PLAYER_EXPERIENCE_PASS_01.md` (append Phase C/D)  
- `docs/agent/qa/PE01_BLIND_C_D_QA.md` (this report)  
- `docs/agent/qa/PE01_BLIND_A_B_QA.md` (link footnote only)  
- `tmp/px_pass_01/**` logs/screenshots/driver artifacts  

Production code/scenes/resources: **unchanged**.

---

## Limitations

- Black-box only; no inspector/state verification.  
- Collision assessed by physical approach + opened frames, not mesh audit.  
- Save/load not exercised in this gate.  
- Driver mouse-capture quirks can interrupt free-look mid-session; fresh relaunch used for authoritative D.

---

## Unmet criteria

None critical. Soft unmet/partial: interaction-teaching clear-after-success (**WARNING**); perfect solid camera collision (**WARNING**).

---

## Recommendation

| Layer | Verdict |
|---|---|
| Evidence collection (fresh C+D) | **PASS** |
| Authoritative Phase C/D first-time Neighbor/prologue route | **PASS** |
| Phase A recovery baseline (historical) | FAIL — superseded for onboarding by C/D |

**READY** for this onboarding/Neighbor acceptance gate, with non-blocking teaching/visual follow-ups.

---

## FINAL D — Post-interaction onboarding correction (source-blind)

**Task gate:** PLAYER EXPERIENCE PASS 01 — final Persona D verification after post-interaction teaching/objective fix  
**Profile:** `tmp/px_pass_01/userdata_D_final`  
**Date:** 2026-08-09  
**Mutation:** none by QA (production already corrected; this run verifies only)  
**GodotIQ / Story / state / source inspection:** none  

Historical C/D section above remains the prior Phase C/D evidence. This section is the **authoritative verdict for the post-interaction correction**.

### Overall status (FINAL D): **PASS**

Critical route completed end-to-end with taught-only controls. After `НОМЕР ПОЛУЧЕН` + OK, the controls card is gone and the objective advances.

### Criteria (FINAL D)

| Criterion | Status | Evidence | Reproduction |
|---|---|---|---|
| Main Menu → click Новая игра | **PASS** | `evidence/D_final/00_main_menu.png` | Isolated launch; click New Game |
| Initial controls + `Познакомься с соседкой.` | **PASS** | `01`/`02` | Open first frames ≤10–15s |
| `Мышь — обзор` explicitly on first-frame card | **WARNING** | Opened `01`/`02` descriptions list WASD + E only | Re-open first frames |
| No debug/internal IDs | **PASS** | All opened HUD frames | Compare vs recovery A |
| Neighbor naturally findable | **PASS** | `09_neighbor_prompt` / `n_aim_01` | Follow goal; pan apartment |
| Semantic `E — Познакомиться` | **PASS** | `09_neighbor_prompt`, `n_aim_01` | Aim Neighbor before contact |
| Dialogue → available option | **PASS** | `n_E_0` | Press E on prompt |
| `НОМЕР ПОЛУЧЕН` + visible OK | **PASS** | `11_number_modal.png` | Select available choice |
| Dismiss OK via visible button | **PASS** | Transition `choice_try_2` → `choice_try_4` / `12_resumed_*` | Click OK |
| Post-OK controls card absent (no generic E) | **PASS** | `12`/`13`/`14`–`20_*` | Inspect resumed gameplay |
| Objective no longer meet-Neighbor; shows first-date step | **PASS** | `ЦЕЛЬ` → `Следующее свидание:` / `доступно` | Same frames |
| Semantic post-contact prompt player-facing | **WARNING** | Not recaptured post-OK (mis-aim/close camera); pre-contact semantic PASS | Re-aim Neighbor after OK |
| Runtime errors / missing resources | **PASS** | Raw log clean of ERROR/WARNING/SCRIPT/Missing | `godot_D_final_20260809_223827.log` |
| Save/load | **N/A** | Not required for this correction gate | — |

### Blocking issues

None.

### Non-blocking issues

1. Opened D_final first frames did not confirm a `Мышь — обзор` line (WASD+E confirmed); look still used via mouse/RMB recovery.  
2. Post-OK re-aim sweeps did not produce a visible post-contact E prompt (camera stuck close / on wall); cannot assert exact post-contact wording this session.  
3. Dialogue choice / OK clicks still flaky under the platform driver (player-visible buttons work).  
4. Free-look capture can drop; RMB-drag look recovers without untaught keys.

### Evidence

- Journal append: `docs/qa/PLAYER_EXPERIENCE_PASS_01.md` → **FINAL D**  
- Screenshots: `tmp/px_pass_01/evidence/D_final/`  
  - Required opened set: `00_main_menu`, `01_new_game_first_frame`, `09_neighbor_prompt`/`n_aim_01`, `11_number_modal`, `12_resumed_post_number`/`13_resumed_gameplay`  
- Raw engine log (≠ journal): `tmp/px_pass_01/logs/godot_D_final_20260809_223827.log`  
- Commands: `tmp/px_pass_01/logs/commands_D_final.txt`  
- Driver: `tmp/px_pass_01/driver/`

### Reproduction steps

1. Ensure project `.godot` cache valid.  
2. Fresh `APPDATA=tmp/px_pass_01/userdata_D_final`; launch Godot 4.7.1 console `--path <project> --resolution 1920x1080 --windowed`.  
3. Click **Новая игра**; read bottom controls + `ЦЕЛЬ`.  
4. Use only taught WASD / look / E to find Neighbor; wait for `E — Познакомиться`; press E.  
5. Click the **Доступно** dialogue option; observe `НОМЕР ПОЛУЧЕН`; click **OK**.  
6. Confirm resumed HUD: no controls card / no generic E; objective is next-date step.  
7. Stop game process; do not touch production saves.

### Changed files (QA only)

- `docs/qa/PLAYER_EXPERIENCE_PASS_01.md` (FINAL D append)  
- `docs/agent/qa/PE01_BLIND_C_D_QA.md` (this section)  
- `tmp/px_pass_01/**` (userdata_D_final, evidence/D_final, logs)

Production code/scenes: **unchanged by QA**.

### Limitations

- Source-blind black-box only.  
- Post-contact semantic prompt wording not visually re-confirmed after OK.  
- Save/load not exercised.  
- Automation click reliability ≠ player click reliability.

### Unmet criteria

None critical. Soft: mouse-line confirmation (**WARNING**); post-contact E wording (**WARNING**).

### Recommendation

| Layer | Verdict |
|---|---|
| Final D evidence collection | **PASS** |
| Post-interaction onboarding correction gate | **PASS** |
| Prior Phase C/D historical | **PASS** (unchanged) |

**PASS** — ready for this correction acceptance. Do not use `READY WITH LIMITATIONS` language; critical route and correction criteria hold with only non-blocking WARNINGs.

