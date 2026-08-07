# M14B_QA — MODULE 14B Independent QA

**Task:** M14B_QA  
**Module:** 14B — Editor & Pre-Media Manual Content  
**Date:** 2026-08-07  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  

## Verdict

**PASS**

---

## Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | ContentDB validate / `MODULE_14B_TEST` ALL PASS | **PASS** | Headless `module_14b_vertical_test.tscn` → `MODULE_14B_TEST: ALL PASS (83)` EXIT=0. Headless `content_data_test.tscn` → `MODULE_03_TEST: ALL PASS (129)` EXIT=0 (includes `validate_all`). Indep QA also `validate_all ok errors=0`. Logs: `tmp/m14b_qa/`. |
| 2 | F5 apartment boots | **PASS** | Live `godotiq_run(play, main)`: `World.current_location_id=apartment`, stage 0, Neighbor present, HUD `mode=GAMEPLAY`. Screenshot `01_apartment_neighbor.png`. |
| 3 | STAGE_3 appearance_space: Editor pair, studio «РЕДАКЦИЯ / СЪЁМКА», `story_point_editor_photo_session`, NO photoshoot auto-run | **PASS** *(stage via `restore_stage` / World travel)* | Indep QA: travel `appearance_space` at STAGE_3 → `npc_girl_magazine_editor` + `npc_rival_magazine_editor` anchors; both actors **spawned**; Label3D text exact; photo point exists; no Dating session / no Photoshoot / no MediaAttention nodes. Visual: `02_appearance_studio.png`. |
| 4 | STAGE_4 Phone handoff Медийность / Фотосессия | **PASS** *(labeled `restore_stage(STAGE_4)`)* | After restore + reconcile: `MEDIA_ATTENTION` unlocked; PhoneJournal story text = `СТАДИЯ 4 / Медийность / Следующий шаг: / Фотосессия у Редактора`. |
| 5 | `try_get` scientist null; no crash | **PASS** | `try_get_girl(girl_scientist)` / `try_get_rival(rival_scientist)` null; STAGE_4 progress IDs resolve null without crash; no `girl_scientist.tres` / `rival_scientist.tres` on disk. |
| 6 | City public NPCs behind PublicCityGate (Stage1 blocked / Stage2 open) | **PASS** | STAGE_1: gate locked + barrier/collision; sculpture/coat/watch NPCs present with girl_z behind gate_z. STAGE_2: gate unlocked, collision off. |
| 7 | Cafe has receipt-notes girl | **PASS** | `npc_girl_cafe_receipt_notes` + `GirlActor` with `girl_id=girl_cafe_receipt_notes`. Screenshot `03_cafe_receipt_notes.png` (КАФЕ + female NPC at spawn). |
| 8 | Open and describe 2–3 screenshots | **PASS** | Three PNGs opened and described below. |
| 9 | Write `docs/agent/qa/M14B_QA.md` | **PASS** | This file. |

---

## Player flow actually executed

1. Independent headless: `MODULE_14B_TEST` ALL PASS (83); `MODULE_03_TEST` / ContentDB ALL PASS (129).
2. Live F5 main → apartment GAMEPLAY + Neighbor.
3. Indep World QA (`tmp/m14b_qa/m14b_indep_qa.tscn`): apartment → city STAGE_1 gate → STAGE_2 open → STAGE_3 appearance_space Editor pair + studio + photo marker (no auto photoshoot) → cafe receipt girl → `restore_stage(STAGE_4)` Phone handoff + scientist try_get null. **39/39 PASS**.
4. Visual capture (windowed Vulkan): apartment / appearance studio / cafe PNGs under `tmp/m14b_qa/`.
5. Confirmed no Scientist production `.tres` files; no MODULE 15 photoshoot runtime exercised.

---

## Edge cases

| Case | Status | Notes |
|------|--------|-------|
| STAGE_3 travel does not auto-start photoshoot | **PASS** | Marker exists only; no Photoshoot/MediaAttention nodes; DatingCore idle |
| STAGE_4 reserved Scientist IDs via try_get | **PASS** | story_girl_id=`girl_scientist`, story_rival_id=`rival_scientist`, both null; Phone shows media handoff instead of broken lookups |
| PublicCityGate STAGE_1 vs STAGE_2 | **PASS** | Locked+barrier at 1; unlocked+collision off at 2; public NPCs physically behind gate |

---

## Screenshot descriptions (opened and inspected)

Evidence: `tmp/m14b_qa/`

### 1) `01_apartment_neighbor.png`

- Grey low-poly apartment room; large blue placeholder pillar right.
- Top-left debug: `mode=GAMEPLAY target=--`.
- Center: female CharacterActor (blonde bob, white tee, rust/orange pants).
- Matches filename: apartment Neighbor gameplay boot.

### 2) `02_appearance_studio.png`

- Purple-floor `appearance_space` studio blockout.
- Large white backdrop; two light-stand cubes; dark camera/tripod placeholder.
- Label3D clearly reads **«РЕДАКЦИЯ / СЪЁМКА»**.
- No photoshoot UI / auto sequence. Matches studio requirement.
- Note: Editor pair not in this standalone visual (spawn verified at STAGE_3 via World travel in indep QA).

### 3) `03_cafe_receipt_notes.png`

- Brown cafe box room; floating **«КАФЕ»** label.
- Female NPC in foreground at receipt-notes spawn; date-table prop + shirtless male NPC also visible (pre-existing cafe cast).
- Matches cafe presence; `girl_id` confirmed programmatically as `girl_cafe_receipt_notes`.

---

## Commands + key log lines

### Headless MODULE 14B

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> --headless res://game/content/test/module_14b_vertical_test.tscn --quit-after 50000
[DF][MODULE_14B_TEST] ALL PASS (83)
MODULE_14B_TEST: ALL PASS (83)
EXIT=0
```

Log: `tmp/m14b_qa/module_14b_vertical.log`

### Headless ContentDB / MODULE 03

```text
... res://world/test/content_data_test.tscn --quit-after 30000
[DF][MODULE_03_TEST] ALL PASS (129)
MODULE_03_TEST: ALL PASS (129)
EXIT=0
```

Log: `tmp/m14b_qa/content_data_test.log`  
(Expected intentional `missing_girl_xyz` push_error during fixture negative lookup.)

### Independent World / Phone / Gate QA

```text
... res://tmp/m14b_qa/m14b_indep_qa.tscn --quit-after 60000
M14B_INDEP_QA: phone_story_text=СТАДИЯ 4 | Медийность | Следующий шаг: | Фотосессия у Редактора
M14B_INDEP_QA: stage4 story_girl_id=girl_scientist try_get=null rival_id=rival_scientist try_get=null
M14B_INDEP_QA: DONE passed=39 failed=0
EXIT=0
```

Log: `tmp/m14b_qa/m14b_indep_qa.log`

### Runtime samples

```text
F5 main → apartment | mode=GAMEPLAY | Spawned_girl_neighbor
STAGE_3 appearance_space → Editor girl+rival spawned; Label3D РЕДАКЦИЯ / СЪЁМКА; story_point_editor_photo_session; no auto photoshoot
STAGE_1 city PublicCityGate locked; public NPCs z behind gate
STAGE_2 gate unlocked / collision off
cafe girl_id=girl_cafe_receipt_notes
restore_stage(STAGE_4) → MEDIA_ATTENTION + Phone Медийность/Фотосессия; try_get scientist null
validate_all ok=true errors=0
```

---

## Blocking issues

None.

## Non-blocking issues

1. Location geometry remains placeholder (flat rooms / blue pillar / primitive studio props); shared low-poly actor looks — visual polish, not 14B functional FAIL.
2. FPS debug HUD (`mode=…`) remains visible in some gameplay shots (pre-existing).
3. GodotIQ sandbox often **times out** on synchronous `GameState.restore_stage` / `World.request_travel`; verification used headless World self-harness + deferred/windowed captures instead. Not a player-route defect.
4. Headless/windowed quit shows RID/ObjectDB leak noise on exit after rapid scene churn — engine cleanup noise, not observed gameplay crash.
5. Standalone play of `appearance_space.tscn` does not spawn STAGE_3 Editor pair (needs Story stage via World); production route + indep World travel does.

## Scope note

No MODULE 15 photoshoot / media runtime / Scientist content. No product code edits by QA.

## Overall status

**PASS**
