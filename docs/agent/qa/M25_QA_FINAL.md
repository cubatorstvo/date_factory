# M25_QA_FINAL — MODULE 25 Wave S final re-QA

**Task:** M25 final re-QA (after Wave S restored city thermos/headphones IDs)  
**Module:** 25 — Content Completion  
**Date:** 2026-08-08  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  
**Evidence:** `tmp/m25_qa_final/`  
**DoD:** `docs/modules/MODULE_25_CONTENT_COMPLETION.md` §114  

**Prior reports:**

| Report | Verdict | Key blocker |
|--------|---------|-------------|
| `docs/agent/qa/M25_QA.md` | **FAIL / NOT READY** | 9 new GirlActors + 3/5 RivalActors empty `spawn_id` / `girl_id` / `rival_id` |
| `docs/agent/qa/M25_QA_RECHECK.md` (Wave R) | **FAIL / NOT READY** | Prior 12 fixed; **thermos + headphones regress to empty** |
| This final (Wave S) | **PASS → recommend READY** | Full **14/14** M25 NPC IDs non-empty and matching |

Wave S claim of 14/14 independently confirmed.

---

## Verdict

**PASS** → recommend **READY**

Independent headless verify of all 14 Module25 new NPCs prints `SUMMARY ok=14 fail=0` / `VERIFY_EXIT 0`. Disk spot-check of `city_hub.tscn` shows restored `spawn_id` + `rival_id` for `rival_city_thermos` and `rival_city_headphones`. `content_data_test` and `dating_test` both print **ALL PASS**. No empty IDs remain in the 9 girls + 5 rivals matrix that blocked prior QA.

---

## Independent checks (this run)

| Check | Status | Evidence |
|-------|--------|----------|
| `tmp/m25_s/verify_all14.gd` — 14/14 | **PASS** | `SUMMARY ok=14 fail=0 total=14`; `VERIFY_EXIT 0` — `tmp/m25_qa_final/verify_all14.log`, `verify_all14_report.txt`, `verify_all14_summary.txt` |
| Disk grep city_hub thermos/headphones `spawn_id`+`rival_id` | **PASS** | Both present and matching — `city_hub_thermos_headphones_grep.txt`, `city_hub_thermos_headphones_context.txt` |
| `content_data_test` | **PASS** | `ALL PASS (649)` — `content_data_test.log` (exit 0) |
| `dating_test` | **PASS** | `ALL PASS (270)` — `dating_test.log` (exit 0) |
| SCRIPT ERROR / Parse Error in this suite | **PASS** | 0 matches in `tmp/m25_qa_final/*.log` |

### verify_all14 matrix (all OK)

| Node | spawn_id | actor id |
|------|----------|----------|
| npc_girl_city_umbrella | girl_city_umbrella | girl_id=girl_city_umbrella |
| npc_girl_city_lanyard | girl_city_lanyard | girl_id=girl_city_lanyard |
| npc_girl_city_crosswalk | girl_city_crosswalk | girl_id=girl_city_crosswalk |
| npc_rival_city_thermos | rival_city_thermos | rival_id=rival_city_thermos |
| npc_rival_city_headphones | rival_city_headphones | rival_id=rival_city_headphones |
| npc_girl_cafe_spoon_stack | girl_cafe_spoon_stack | girl_id=girl_cafe_spoon_stack |
| npc_girl_cafe_hot_sauce | girl_cafe_hot_sauce | girl_id=girl_cafe_hot_sauce |
| npc_girl_cafe_sugar_geometry | girl_cafe_sugar_geometry | girl_id=girl_cafe_sugar_geometry |
| npc_rival_cafe_menu_holder | rival_cafe_menu_holder | rival_id=rival_cafe_menu_holder |
| npc_girl_gym_timer | girl_gym_timer | girl_id=girl_gym_timer |
| npc_rival_gym_plate_counter | rival_gym_plate_counter | rival_id=rival_gym_plate_counter |
| npc_girl_appearance_coat_check | girl_appearance_coat_check | girl_id=girl_appearance_coat_check |
| npc_girl_appearance_mannequin | girl_appearance_mannequin | girl_id=girl_appearance_mannequin |
| npc_rival_appearance_ringlight | rival_appearance_ringlight | rival_id=rival_appearance_ringlight |

### Disk thermos/headphones (Wave R regression site)

From `world/locations/city_hub/city_hub.tscn` (this final):

- `npc_rival_city_thermos`: `spawn_id = &"rival_city_thermos"`; `RivalActor.rival_id = &"rival_city_thermos"`
- `npc_rival_city_headphones`: `spawn_id = &"rival_city_headphones"`; `RivalActor.rival_id = &"rival_city_headphones"`

Regression from `M25_QA_RECHECK` (`spawn=[] rival=[]`) is **cleared**.

---

## Spec §114 critical items — readiness summary

Scope of this final: confirm Wave S closed the **blocking NPC-ID route**, and that catalog/dating regressions remain green. Broader §114 items already PASS’d in `M25_QA.md` (catalog, matrix, media, flavor/gags, upgrade visuals, schema v1, headless suite) are **carried forward** unless re-broken; this run re-verified content + dating suites.

| §114 critical theme | Status | Basis |
|---------------------|--------|-------|
| production girls exact23 / ordinary16 / story·final7 | **PASS** | Prior indep catalog verify (`M25_QA`); content suite still ALL PASS 649 |
| 4×4 ordinary primary×secondary unique/complete | **PASS** | `_test_module25_ordinary_matrix` in content suite |
| 9 specified new ordinary girls exist + identity content | **PASS** | Catalog + content suite (prior + this content_data_test) |
| 9 new GirlActors physical placement **with content IDs** | **PASS** | verify_all14 9/9 girls OK (was FAIL in M25_QA; PASS after Wave R; still PASS) |
| Discovery 22; clues/speech/signature wiring (ordinary) | **PASS** | Prior catalog + content/dating suites |
| 16 signature pools/events; +12 cafe common; greetings/farewells | **PASS** | Prior catalog; dating_test ALL PASS 270 |
| Feasible ± routes / secondary conditions / repeat-date planner | **PASS** | dating_test ALL PASS 270 |
| rivals exact19 / ordinary12; 5 new ordinary rivals; no new story rivals | **PASS** | Prior catalog |
| Each new rival physical production placement **with content IDs** | **PASS** | verify_all14 5/5 rivals OK (thermos/headphones restored Wave S) |
| Media old7 prefix + new9 order | **PASS** | Prior `M25_QA` MediaContent check |
| Flavor ≥24 / gags ≥12 / presentation-only; upgrade visual tiers | **PASS** | Prior `M25_QA` (non-blocking screenshot quality WARNINGs remain) |
| SAVE_SCHEMA_VERSION=1; old Module24 fixture; new IDs save/load | **PASS** | Prior save suite ALL PASS 138 (+old14) |
| No MODULE26 balance ahead | **PASS** | Prior grep; this QA made no product changes |
| Headless MODULE02–24 regressions listed in prior QA | **PASS (carried)** | This final re-ran content 649 + dating 270; full suite not re-run (see note) |

**Note:** Full MODULE02–24 regression matrix was independently green in `M25_QA.md` §3. This final focused on the Wave S blocker (14 NPC IDs) + catalog/dating smoke. No evidence of catalog regression.

---

## Edge cases

1. **Partial-verify false confidence (Wave R)** — asserting only 12 nodes missed thermos/headphones empty. Wave S uses `verify_all14.gd` covering all 14; this final ran that script → **PASS**.  
2. **Scene-edit ID strip** — previously OK thermos/headphones lost exports during Wave R city_hub edits; disk + instantiate now show IDs restored.

---

## Commands executed

```powershell
$godot = "C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe"
$root = "C:\Users\User\Documents\GodotProjects\date_factory"

& $godot --path $root --headless -s res://tmp/m25_s/verify_all14.gd
# Disk: Select-String city_hub.tscn thermos|headphones|spawn_id|rival_id → tmp/m25_qa_final/
& $godot --path $root --headless --quit-after 120000 res://world/test/content_data_test.tscn
& $godot --path $root --headless --quit-after 120000 res://game/dating/test/dating_test.tscn
```

Notes:

- Expected intentional `ERROR: [ContentDB] missing girl: missing_girl_xyz` in content fixture path.
- `verify_all14` printed `VERIFY_EXIT 0` then engine teardown SIGSEGV (exit `-1073741819`) — known headless quit noise; **not** treated as product FAIL when SUMMARY is 14/14.
- content/dating process exit 0 with ALL PASS lines.

---

## Non-blocking issues (unchanged from prior QA)

1. Screenshot filename/content mismatches from wave L/N evidence (apartment planning notes, city bus stop weak, lab date plates duplicate) — presentation evidence quality, not ID wiring.  
2. Headless quit SIGSEGV / ObjectDB·RID leak after successful asserts.  
3. Broader pre-M25 ordinary NPC ID gaps (bicycle/chalk/laptop etc.) observed in original dump — outside the Module25 new 9+5 matrix; Orchestrator may track separately.

---

## Overall status

**Overall status:** **PASS**

**Blocking issues:** none for the Wave S / 14-NPC ID critical route.

**Non-blocking issues:** prior screenshot evidence quality; headless teardown noise; optional pre-M25 NPC export drift outside new 9+5.

**Evidence:** `tmp/m25_qa_final/`

- `verify_all14.log` / `verify_all14_report.txt` / `verify_all14_summary.txt` / `verify_all14.exit.txt`
- `city_hub_thermos_headphones_grep.txt` / `city_hub_thermos_headphones_context.txt`
- `content_data_test.log` / `content_data_test.exit.txt`
- `dating_test.log` / `dating_test.exit.txt`

**Reproduction steps:**

1. `Godot … --headless -s res://tmp/m25_s/verify_all14.gd` → expect `SUMMARY ok=14 fail=0` and `VERIFY_EXIT 0`.  
2. Grep `world/locations/city_hub/city_hub.tscn` for thermos/headphones → non-empty matching `spawn_id` + `rival_id`.  
3. Run `content_data_test.tscn` → `ALL PASS (649)`.  
4. Run `dating_test.tscn` → `ALL PASS (270)`.  
5. Cross-check prior FAIL reports: empty-ID matrix in `M25_QA.md` and thermos/headphones empty in `M25_QA_RECHECK.md` are resolved.

**Orchestrator decision:** recommend **PASS / READY** for MODULE 25. Do not start MODULE 26 until Orchestrator closes acceptance. Non-blocking screenshot polish can be follow-up.
