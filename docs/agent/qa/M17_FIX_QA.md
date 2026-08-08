# M17_FIX_QA — Scientist production wiring

**Task:** M17FIX_C_QA  
**Date:** 2026-08-08  
**Repo:** `C:\Users\User\Documents\GodotProjects\date_factory`  
**Godot:** `Godot_v4.7.1-stable_win64_console.exe`  
**Spec DoD:** `docs/modules/MODULE_17_FIX_SCIENTIST_PRODUCTION_WIRING.md` §13  

## Overall status

**PASS**

Critical production route proven independently: on an already-loaded `city_hub` at STAGE_4, real `DatingOverload.problem_recognized` (media start → advance days → personal date → `_try_recognize_problem` → signal) spawns Scientist + rival without scene reload and without calling `_refresh_spawn` on city anchors.

## Criteria table

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Headless `first_clone_test.tscn` ALL PASS (~112) | **PASS** | `tmp/m17_fix_qa/first_clone_self_test.log` — `ALL PASS (112)`; includes live wiring A–F, STORY_PREREQUISITE, FirstClone rates, no President |
| 2 | F5/main boots apartment | **PASS** | `tmp/m17_fix_qa/f5_main_boot.log` — `[DF][MODULE_12] Boot -> apartment via World`, Player ready; shot `01_apartment_boot.png` |
| 3a | city_hub STAGE_4 before recognition: scientist/rival anchors empty | **PASS** | Indep harness: anchor child_count=0; no `Spawned_girl_scientist` / `Spawned_rival_scientist` |
| 3b | After REAL recognition path: both spawn without reload / without `_refresh_spawn` | **PASS** | Signal count=1; same `city_hub` location; girl/rival children=1; harness never called `_refresh_spawn` |
| 4 | `GirlDiscovery.begin_attempt` before recognition → `STORY_PREREQUISITE` | **PASS** | ok=false, reason=STORY_PREREQUISITE; no cooldown/contact side effects |
| 5 | FirstClone WORK 1/1/0 (or DATING 1/0/1), rates 0 | **PASS** | total=1 working=1 dating=0; mpm=0 dpm=0; also covered by MODULE_17_TEST 66/68 |
| 6 | Placement rival → girl → ToLab | **PASS** (math) / **WARNING** (visual) | Dist rival–girl ≈ 2.85 m; rival east of girl; girl x aligns with ToLab. Screenshots show city hub NPCs but do not clearly frame `ЛАБОРАТОРИЯ` label |
| 7 | No MODULE 18 / no President | **PASS** | No `girl_president` / `rival_president` / MODULE_18 spec / `game/clone_incremental` |
| DoD | `requires_overload_recognized` exists, default false | **PASS** | MODULE_17_TEST + city anchors `= true`; default-false spawn test A |
| DoD | Event-driven refresh on `problem_recognized` | **PASS** | Live signal → spawn without manual refresh |
| DoD | Reset refresh works | **PASS** | MODULE_17_TEST state_reset clears scientist anchors |
| DoD | city_hub contains both Stage4 anchors requiring overload | **PASS** | `npc_story_scientist` + `npc_story_scientist_rival`, stage 4, flag true |
| DoD | Scientist discovery blocked before recognition; dedicated non-failure result | **PASS** | `STORY_PREREQUISITE` |
| Edge | After recognition, rival still gates Scientist | **PASS** | `STORY_RIVAL_REQUIRED` |
| Edge | Lab travel blocked at STAGE_4 | **PASS** | travel laboratory != SUCCESS |
| Control return | Re-enter city_hub STAGE_4 recognized | **PASS** | apartment → city_hub; both still spawned |
| Save/load file API | Persist via GameState save file | **WARNING** | No `save_to_path` / export API found; re-travel used instead |

## Player flow verified (independent harness)

```text
1. World.reset_to_start → apartment + neighbor
2. Seed STAGE_4 + media → DatingOverload started (not recognized)
3. GirlDiscovery.begin_attempt(girl_scientist) → STORY_PREREQUISITE
4. Travel city_hub (loaded, stays loaded)
5. BEFORE: npc_story_scientist / npc_story_scientist_rival empty
6. LIVE: advance_day ×2 + personal date(s)
   → DatingOverload.problem_recognized emitted once
   → BOTH anchors spawn (no reload, no _refresh_spawn)
7. Placement transforms: rival (-1.8,0.05,3.4) → girl (-4.5,0.05,2.5) → ToLab (-4.5,1.1,5.2)
8. begin_attempt after recognition → STORY_RIVAL_REQUIRED
9. Lab blocked at STAGE_4
10. Leave apartment / re-enter city_hub → pair still present
11. Assisted STAGE_5 + FirstClone WORK → 1/1/0 rates 0
12. No President / MODULE 18
```

**Critical rule compliance:** recognition used production path (`_ensure_started_from_media` + day advance + `Relationships.apply_date_result` → `_try_recognize_problem` → `problem_recognized.emit`). Did **not** call `mark_dating_overload_problem_recognized` + manual emit for the spawn proof. Did **not** call `_refresh_spawn` on city anchors.

## Screenshot descriptions (opened and inspected)

| File | Actual content |
|------|----------------|
| `01_apartment_boot.png` | Apartment interior, title «КВАРТИРА», neighbor NPC (blonde / white tee / orange pants), date table + самооценка props, `mode=GAMEPLAY`. Matches name. |
| `02_city_before_recognition.png` | Nearly blank gray frame with FPS crosshair and `[E] В квартиру` / `target=ToApartment`. **Does not** clearly show lab-gate whitebox; empty-anchor claim rests on node checks, not this image. Name overstates visual coverage. |
| `03_city_after_live_recognition.png` | City hub whitebox: player body + multiple identical female NPCs, blue transition blocks, «КАФЕ» label, apartment prompt still on HUD. Confirms city after recognition with NPCs present; **does not** clearly label Scientist/rival/ToLab. |
| `04_placement_rival_girl_tolab.png` | Similar city hub third-person-ish view with player + three female NPCs near café/apartment side. Placement order proven by logged transforms, not by a clear rival→girl→«ЛАБОРАТОРИЯ» composition. |
| `05_city_reenter_stage4.png` | Same hub composition after apartment round-trip; NPCs still present. Supports re-enter spawn persistence visually at hub level. |
| `06_lab_clone_work.png` | Laboratory: clone/player body on green WORK pad labeled «РАБОТА», calibration unit «КАЛИБРОВКА / УСТАНОВКА», partial «ЛАБО…», prompt `[E] В город`. Matches FirstClone WORK assignment smoke. |

## Runtime / logs

| Log | Result |
|-----|--------|
| `tmp/m17_fix_qa/first_clone_self_test.log` | ALL PASS (112); exit 0; exit-time RID leaks only |
| `tmp/m17_fix_qa/f5_main_boot.log` | Boot → apartment; Player ready; exit 0 |
| `tmp/m17_fix_qa/m17_fix_indep_qa_headless.log` | DONE passed=61 failed=0 |
| `tmp/m17_fix_qa/m17_fix_indep_qa_windowed.log` | DONE passed=61 failed=0 + screenshots |
| `tmp/m17_fix_qa/m17_fix_indep_qa_report.txt` | Capture journal (not raw-only engine log) |

Harness sources (evidence-only, not product):  
`tmp/m17_fix_qa/m17_fix_indep_qa.gd`, `tmp/m17_fix_qa/m17_fix_indep_qa.tscn`

## Blocking issues

None.

## Non-blocking issues

1. **City lab-gate screenshots weak** — QA cameras often captured apartment/café side of hub; Scientist/rival/ToLab not visually unambiguous. Runtime spawn + transform math still PASS.
2. **No GameState file save API** in this build for a full save/load round-trip; re-travel persistence used instead.
3. **Engine exit RID / ObjectDB leaks** in headless and windowed runs (pre-existing pattern; not gameplay blockers).
4. **Shot `02` naming vs content** — file name implies “before recognition at gate,” image is mostly empty gray toward apartment transition.

## Unmet criteria

None for critical DoD / must-verify list. Visual placement framing is limited (WARNING), not a functional unmet.

## Reproduction steps

```powershell
$GODOT = "C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe"
$REPO  = "C:\Users\User\Documents\GodotProjects\date_factory"

# 1) Headless MODULE 17 suite
& $GODOT --path $REPO --headless "res://game/first_clone/test/first_clone_test.tscn"

# 2) F5 main boot
& $GODOT --path $REPO --quit-after 4

# 3) Independent LIVE recognition / spawn QA (windowed for screenshots)
& $GODOT --path $REPO "res://tmp/m17_fix_qa/m17_fix_indep_qa.tscn"
```

## Verdict for Orchestrator

**PASS** — Scientist production wiring accepts live `DatingOverload.problem_recognized` spawn on loaded city_hub; STORY_PREREQUISITE + FirstClone calibration/assignment unchanged; MODULE 18 absent. Ready for Orchestrator READY decision (QA does not use READY WITH LIMITATIONS).
