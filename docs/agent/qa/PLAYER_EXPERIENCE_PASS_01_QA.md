# PLAYER EXPERIENCE PASS 01 — Independent Final QA

**Task id:** PE01-FINAL-QA  
**Role:** df-qa-worker (independent; not implementation author)  
**Date:** 2026-08-09  
**Gameplay mutation by this QA:** none  
**Writable artifacts:** this report; `tmp/pe01_final_qa/**`  
**Godot:** 4.7.1 console `C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe`  
**GodotIQ MCP:** unavailable this session → native CLI used  

Companion journals / prior blind QA (historical, not re-authored):  
- `docs/qa/PLAYER_EXPERIENCE_PASS_01.md`  
- `docs/agent/qa/PE01_BLIND_A_B_QA.md`  
- `docs/agent/qa/PE01_BLIND_C_D_QA.md`  

---

## Summary

Independent audit of PLAYER EXPERIENCE PASS 01 confirms the critical first-time route is player-reachable on fresh isolated profiles: Main Menu → **Новая игра** → readable apartment + controls/`ЦЕЛЬ` → taught move/look → find Neighbor → real **E** → dialogue → **`НОМЕР ПОЛУЧЕН`** → OK → controls card gone + objective **`Следующее свидание: доступно`**.

Focused PE01 tests re-run by this QA all PASS. Full RC suite is **34/35** with pre-existing `world_location` FAIL (City/Cafe empty NPC marker IDs from Art Pass 01 baseline `86cb0f9`); that failure is **out of PE01 ownership** and does **not** break apartment → Neighbor prologue. It **does** prevent claiming a fully green RC suite.

**Overall verdict: READY**

---

## Changed files reviewed (production / tests / docs)

### Production (git modified)

| Path | Scope assessment |
|---|---|
| `characters/player/player.gd`, `player.tscn` | Onboarding / interaction evidence wiring; no save schema |
| `ui/hud/game_hud.gd` | Objective HUD + controls onboarding; uses existing `SaveSystem` **settings** APIs for tutorial-seen ids only (`get/set_tutorial_seen_ids`, `save_settings`) — not game-save schema |
| `ui/tutorial/tutorial_prompt.gd` | Tutorial card text/behavior |
| `world/art/donor_import/apartment/apartment.tscn` | Added essential furniture/exit `StaticBody3D` colliders under `Colliders/` |
| `world/locations/apartment/apartment.tscn` | Spawn facing/clearance tweak; restore Neighbor `content_id = &"girl_neighbor"` |

### Focused tests (untracked)

- `ui/hud/test/pe01_onboarding_hud_*`  
- `ui/hud/test/pe01_first_frame_capture.*`  
- `ui/hud/test/pe01_neighbor_flow_capture.*`  
- `world/test/apartment_onboarding_physics_*`  
- `world/test/apartment_spawn_visual_capture.*`  

### Docs / evidence

- `docs/agent/{ACCEPTANCE,DECISIONS,OWNERSHIP}.md`  
- `docs/qa/PLAYER_EXPERIENCE_PASS_01.md`  
- `docs/agent/qa/PE01_BLIND_*.md`  
- `tmp/px_pass_01/**` (driver, logs, screenshots)  

### Explicitly unchanged / clean

- `project.godot` — clean  
- Save schema modules / `save_schema` value — remains `1` in boot + RC save logs  
- City/Cafe scenes — not in PE01 diff (matches known `world_location` ownership)  

---

## Actual player flow (verified by opening images)

Authoritative black-box path: **Persona D_final** (+ corroboration from C/D and automated captures).

| Step | Status | Opened-image evidence (content, not filename trust) |
|---|---|---|
| Fresh Main Menu | **PASS** | `D_final/00_main_menu.png`: DATE FACTORY / Главное меню; **Новая игра** highlighted; Continue dim; v1.0.0 |
| First gameplay frame room-readable | **PASS** | `D_final/01_*` & `C/01_*`: bed, blue curtains, dresser, round table visible; not door face-plant |
| WASD / Mouse / E taught | **PASS** (with WARNING) | `C/01_*` and `PE01_fix3/01_*`: full card `WASD — движение` / `Мышь — обзор` / `E — взаимодействие`. Opened `D/01_*` and `D_final/01_*` show WASD+E only (Мышь line missing in those captures) — see Non-blocking |
| Persistent `ЦЕЛЬ` meet Neighbor | **PASS** | Top-right `ЦЕЛЬ` / `Познакомься с соседкой.` on first frames + Neighbor approach frames |
| No debug overlay | **PASS** | No `mode=` / internal target labels on C/D/D_final HUD frames (contrast recovery A) |
| Find Neighbor + `E — Познакомиться` | **PASS** | `C/08_neighbor_seen.png`, `D_final/09_neighbor_prompt.png`: Neighbor from behind; prompt `E — Познакомиться`; pre-success bottom `E — взаимодействие` still present |
| Real E → dialogue | **PASS** | `D_final/n_E_0.png`: mug dialogue; available choice highlighted **Доступно** |
| Immediate feedback `НОМЕР ПОЛУЧЕН` | **PASS** | `D_final/11_number_modal.png`, `C/10_first_story_next_step.png`: modal + body + **OK** |
| Dismiss OK → no controls card; objective advances | **PASS** | `D_final/12_resumed_post_number.png`, `13_resumed_gameplay.png`: no bottom teaching card; `ЦЕЛЬ` = `Следующее свидание:` / `доступно`. Automated `PE01_fix2/10_after_number_received.png` also shows updated objective + `E — номер уже получен` |
| Story-locked city door explained | **PASS** | `D/d_mouse_c_rmb.png`: `E — Недоступно — Пока недоступно по сюжету` while `ЦЕЛЬ` still meet Neighbor |
| Collision plausible | **PASS** (WARNING soft camera) | Diff adds furniture/exit static colliders; `PE01_APT_PHYS` 66/66; `PE01_APT_VIS` capsule blocked inside bed/table/wardrobe/fridge/exit volumes. Player `col_*` approach shots show near-surface / clip views → soft camera vs hard body |

---

## Criteria table

| Criterion | Status | Evidence | Reproduction |
|---|---|---|---|
| Fresh C/D/final-D critical route without source/API cheats | **PASS** | Journals + opened C/D/D_final PNGs; driver keyboard/mouse only | Isolated APPDATA; click Новая игра; play |
| Tutorial teaches WASD/Mouse/E initially | **PASS** | C + PE01_fix3 + first-frame test (7 PASS). D/D_final black-box frames: **WARNING** missing Мышь | Fresh New Game ≤10s |
| Objective updates after Neighbor | **PASS** | D_final `12`/`13`; PE01_fix2 `10_*` | Complete number modal + OK |
| Interaction teaching clears after success | **PASS** | D_final resumed frames: bottom card absent | Same |
| No persistent production errors on route | **PASS** | Raw C/D/D_final engine logs: clean boot, no SCRIPT/Missing; `Player ready` | Inspect raw logs below |
| Spawn / Neighbor / colliders demonstrated | **PASS** | Opened spawn/Neighbor frames + apt phys/vis tests | Focused scenes + black-box |
| Focused PE01 tests pass | **PASS** | Re-run logs under `tmp/pe01_final_qa/` | Commands below |
| RC fully green | **FAIL** (suite) / **non-blocking for PE01** | `tmp/qa/summary.txt` = 34/35; `world_location` empty City/Cafe spawn_ids | Baseline Art Pass debt |
| Save schema unchanged | **PASS** | Boot `save_schema=1`; no schema-bearing production diffs; RC `save_system` / `game_state_save` PASS | Diff + RC logs |
| Donor / PACK019 runtime refs in PE01 paths | **PASS** (0 hits) | rg over player/hud/tutorial/apartment paths | Commands below |

---

## Commands executed (this QA)

```text
# Inventory / RC
Get-Content tmp\qa\summary.txt
Select-String tmp\qa\world_location.log -Pattern "FAIL|empty NpcSpawnPoint"

# Donor / PACK019 / save hygiene
rg -n "date_factory_legacy|PACK019|PACK_019|res://\.\./" characters/player ui/hud ui/tutorial world/locations/apartment world/art/donor_import/apartment
git status --short -- project.godot
git diff --stat -- characters ui/hud ui/tutorial world/art/donor_import/apartment world/locations/apartment docs/agent

# Focused tests (isolated APPDATA under tmp/pe01_final_qa)
godot --path <project> --headless --quit-after 45 res://ui/hud/test/pe01_onboarding_hud_test.tscn
# → PE01_ONBOARDING_HUD_SELF_TEST_PASSED passed=33

godot --path <project> --resolution 1280x720 --windowed --quit-after 45 res://ui/hud/test/pe01_first_frame_capture.tscn
# → PE01_FIRST_FRAME_CAPTURE_PASSED passed=7

godot --path <project> --resolution 1280x720 --windowed --quit-after 90 res://ui/hud/test/pe01_neighbor_flow_capture.tscn
# → PE01_NEIGHBOR_FLOW_CAPTURE_PASSED passed=15

godot --path <project> --headless --quit-after 60 res://world/test/apartment_onboarding_physics_test.tscn
# → PE01_APT_PHYS: ALL PASS (66)

godot --path <project> --resolution 1280x720 --windowed --quit-after 90 res://world/test/apartment_spawn_visual_capture.tscn
# → PE01_APT_VIS: ALL PASS (18)
```

Black-box player launches (prior independent QA; re-audited here by opening their evidence + raw logs, not re-driving the full route):

```text
APPDATA=tmp/px_pass_01/userdata_{C|D|D_final}
godot --path <project> --resolution 1920x1080 --windowed
# logs: godot_C_20260809_220623.log, godot_D_20260809_222512.log, godot_D_final_20260809_223827.log
```

---

## Raw engine logs vs capture journals

| Kind | Path | Role |
|---|---|---|
| **Capture journal / player journal** | `docs/qa/PLAYER_EXPERIENCE_PASS_01.md` | Human/driver narrative; **not** engine stdout |
| **Raw engine log (C)** | `tmp/px_pass_01/logs/godot_C_20260809_220623.log` | Godot process stdout |
| **Raw engine log (D)** | `tmp/px_pass_01/logs/godot_D_20260809_222512.log` | Godot process stdout |
| **Raw engine log (D_final)** | `tmp/px_pass_01/logs/godot_D_final_20260809_223827.log` | Godot process stdout |
| **This QA test logs** | `tmp/pe01_final_qa/*.log` | Focused test stdout |

### Raw D_final engine log (excerpt; authoritative clean boot)

```text
Godot Engine v4.7.1.stable.official...
Vulkan 1.4.303 - Forward+ - NVIDIA GeForce RTX 4060 Laptop GPU
[DF][MODULE_*] ... ready (GameState through SaveSystem)
DATE FACTORY
version=1.0.0
save_schema=1
[DF][MODULE_24] Boot -> title menu (World deferred)
[DF][MODULE_01] Player ready
```

Scan of C/D/D_final raw logs: **0** matches for `ERROR|SCRIPT ERROR|WARNING|Failed to|Missing|Parse Error` in gameplay boot body (34 lines each).  
Exit-time RID/resource leak noise from headless/windowed **test** runs is present in `tmp/pe01_final_qa/*` and is treated as engine teardown noise, not production route errors.

---

## Screenshots opened (this QA)

| File | Actual content observed |
|---|---|
| `D_final/00_main_menu.png` | Real title menu; Новая игра selected |
| `D_final/01_new_game_first_frame.png` | Readable room; ЦЕЛЬ meet Neighbor; WASD+E card; `E — Стол для свидания`; no debug; **Мышь line not visible in this frame** |
| `C/01_new_game_first_frame.png` | Same spawn family; **full WASD/Мышь/E** card |
| `PE01_fix3/01_new_game_first_frame.png` | Automated first-frame guarantee: full WASD/Мышь/E |
| `C/08_neighbor_seen.png` | Neighbor; `E — Познакомиться`; lingering generic E teaching |
| `D_final/09_neighbor_prompt.png` | Neighbor at door; `E — Познакомиться` |
| `D_final/n_E_0.png` | Mug dialogue + available choice |
| `D_final/11_number_modal.png` / `C/10_first_story_next_step.png` | `НОМЕР ПОЛУЧЕН` + OK |
| `D_final/12_resumed_post_number.png` / `13_resumed_gameplay.png` | No controls card; `Следующее свидание: доступно` |
| `PE01_fix2/10_after_number_received.png` | Post-number: objective updated; `E — номер уже получен`; no teaching card |
| `D/d_mouse_c_rmb.png` | Story-lock door prompt; Neighbor visible; goal still meet Neighbor |
| `C/col_bed_front.png`, `C/col_exit_front.png` | Near-surface approach frames (support soft camera WARNING more than hard-body proof) |

Reviewed copies mirrored under `tmp/pe01_final_qa/evidence_reviewed/`.

---

## Regression table

| Suite / check | Result | Blocks PE01? |
|---|---|---|
| PE01 onboarding HUD self-test | **33 PASS** | No |
| PE01 first-frame capture | **7 PASS** | No |
| PE01 neighbor flow capture | **15 PASS** | No |
| PE01 apartment physics | **66/66 PASS** | No |
| PE01 apartment visual/collision capture | **18/18 PASS** | No |
| RC `save_system` | **PASS** (138) | No |
| RC `game_state_save` | **PASS** (88) | No |
| RC full suite | **34/35** | **No for PE01 route** |
| RC `world_location` | **FAIL** — empty `NpcSpawnPoint.spawn_id` / NPC marker checks on City + Cafe (Art Pass 01 baseline; PE01 does not touch those scenes) | **No** for apartment→Neighbor; **Yes** for claiming fully green RC / ordinary City-Cafe NPC binding after Stage 1 |

---

## Save / schema and donor / PACK019

| Check | Result |
|---|---|
| `save_schema` in boot / RC | `1` unchanged |
| PE01 diffs alter save format / domain restore | **No** — only tutorial-seen settings persistence via existing SaveSystem settings API |
| `project.godot` | Clean |
| Runtime refs to `../date_factory_legacy` in PE01 production paths | **0** |
| Runtime `PACK019` / `PACK_019` refs in those paths | **0** |
| Apartment art lives under in-project `world/art/donor_import/apartment/` | Copy/import path (not live donor mount) |

---

## Blocking issues

None on the PE01 critical Main Menu → Neighbor → number-received → post-OK HUD correction route.

---

## Major (non-blocking) issues

1. **RC not fully green (34/35):** `world_location` still fails on City/Cafe empty NPC marker IDs inherited from Art Pass 01. Outside PE01 writable scope; must not be reported as PE01-fixed.  
2. **Black-box Мышь intermittency:** taught-only D/D_final opened first frames omit `Мышь — обзор` even though C + automated first-frame test prove the line exists on this build. Taught-only purity risk if capture/driver clears look teaching early — mitigated by C evidence + focused test PASS.  
3. **Camera soft collision:** player body blocked (tests + collider add), but FPS camera frequently clips into brown/near-wall surfaces in approach shots.

---

## Minor issues

1. NPC clothing / close-up silhouette reads unfinished (bikini / underwear; camera often wedged behind Neighbor).  
2. Platform-driver OK/choice clicks flaky; player-visible buttons work.  
3. Free-look mouse capture can drop mid automation session (RMB drag recovers).  
4. Post-OK semantic re-prompt not always reacquired in black-box sweeps (aim/driver); automated capture shows `E — номер уже получен`.  
5. Headless apartment visual capture incomplete; windowed re-run required (done; 18/18).

---

## Limitations / unmet criteria

- This final QA did **not** re-drive a full live black-box Main Menu→Neighbor session; it independently opened prior C/D/D_final evidence, raw engine logs, git diff, and re-ran focused tests.  
- Full-game save/load during prologue was **not** re-exercised beyond RC save suite PASS + schema hygiene.  
- Soft unmet: intermittent Мышь visibility in some black-box first frames (**WARNING**, not critical FAIL given C + PE01_fix3 + first-frame test).  
- Soft unmet: perfect camera collision (**WARNING**).  
- **Unmet for “fully green RC”:** world_location FAIL remains — correctly reported; does not unmet the PE01 apartment onboarding acceptance under current OWNERSHIP/ACCEPTANCE.

---

## Edge cases checked

1. **Story-locked exit vs active objective** — door explains lock; `ЦЕЛЬ` stays Neighbor until number received (**PASS**).  
2. **Post-success teaching/objective** — controls card cleared; objective advances to next-date (**PASS** on D_final).  
3. **Taught-only vs FPS-allowed** — C (FPS OK) and D/D_final (taught-only) both complete critical route (**PASS**, Мышь WARNING on D captures).  

---

## Overall status

| Layer | Verdict |
|---|---|
| Critical player route (C / D / D_final) | **PASS** |
| Focused PE01 automated tests | **PASS** |
| Save schema / donor / PACK019 hygiene | **PASS** |
| Full RC suite green | **FAIL** (34/35; known out-of-scope) |
| PE01 acceptance under current specification | **READY** |

### Blocking issues
None for PE01 critical route.

### Non-blocking issues
RC 34/35 `world_location`; Мышь intermittency on some black-box frames; camera clip; NPC visual polish; driver OK flakiness.

### Evidence
- Journal: `docs/qa/PLAYER_EXPERIENCE_PASS_01.md`  
- Blind QA: `docs/agent/qa/PE01_BLIND_A_B_QA.md`, `PE01_BLIND_C_D_QA.md`  
- Screenshots: `tmp/px_pass_01/evidence/{C,D,D_final,PE01_fix2,PE01_fix3}/`  
- Raw engine logs: `tmp/px_pass_01/logs/godot_{C,D,D_final}_*.log`  
- This QA logs/evidence: `tmp/pe01_final_qa/`  
- RC: `tmp/qa/summary.txt`, `tmp/qa/world_location.log`  

### Reproduction steps
1. Keep `.godot` import cache valid.  
2. Launch with isolated APPDATA and `--resolution 1920x1080 --windowed`.  
3. Click **Новая игра**; confirm controls + `ЦЕЛЬ` within 10–15s.  
4. Use WASD/mouse/E; find Neighbor; press E on `Познакомиться`.  
5. Choose available dialogue option; dismiss **`НОМЕР ПОЛУЧЕН`** OK.  
6. Confirm teaching card gone and objective shows next date available.  
7. Optionally aim city door for story-lock wording.  
8. Run focused PE01 test scenes listed above; expect all PASS.  
9. Expect RC 34/35 until City/Cafe NPC markers are restored outside this pass.

---

## Exact verdict

**READY**

Do not describe the pass as fully green RC. The known `world_location` 34/35 failure remains and is out of PE01 scope; it does not block acceptance of the apartment onboarding / Neighbor prologue experience under the current specification.
