# M25_QA_RECHECK — MODULE 25 Wave R NPC ID re-QA

**Task:** M25 Wave R recheck (after critical empty NPC ID FAIL)  
**Prior report:** `docs/agent/qa/M25_QA.md` (FAIL)  
**Date:** 2026-08-08  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  
**Evidence:** `tmp/m25_qa_recheck/`

## Verdict

**FAIL** → recommend **NOT READY**

Wave R **did** wire the previously broken **9 GirlActors + 3 RivalActors** (menu_holder / plate_counter / ringlight). Independent instantiate + `.tscn` spot-check confirm matching non-empty IDs for those 12.

**New critical regression:** the **2 rivals that previously PASS’d** (`npc_rival_city_thermos`, `npc_rival_city_headphones`) now have **empty `spawn_id` / `rival_id`**. Wave R’s `verify_npc_ids.gd` only asserts the 12-node set and does **not** cover thermos/headphones — so executor PASS missed this.

Requirement “all **9 girls + 5 rivals** non-empty matching IDs” is **unmet** (9/9 girls OK, **3/5** rivals OK, **2/5** rivals empty).

---

## Recheck criteria

| Check | Status | Evidence |
|-------|--------|----------|
| `tmp/m25_r/verify_npc_ids.gd` — 9 girls + 3 rivals | **PASS** | `VERIFY_EXIT 0`; `tmp/m25_qa_recheck/verify_npc_ids.log`, `verify_report.txt`, `verify_exit.txt` (`fail=false`) |
| Full dump includes thermos/headphones | **FAIL** | `tmp/m25_qa_recheck/npc_id_dump.txt` — both `spawn=[] rival=[]` |
| Targeted thermos/headphones assert | **FAIL** | `tmp/m25_qa_recheck/thermos_headphones_check.txt` |
| `.tscn` spot-check previously broken nodes | **PASS** | `tmp/m25_qa_recheck/tscn_id_spotcheck.txt` — spawn_id + girl_id/rival_id present for all 12 |
| `.tscn` thermos/headphones | **FAIL** | `city_hub.tscn` nodes exist with `npc_kind = 2` but **no** `spawn_id` / `rival_id` properties |
| `content_data_test` | **PASS** | `ALL PASS (649)` — `content_data_test.log` |
| `dating_test` | **PASS** | `ALL PASS (270)` — `dating_test.log` |
| Catalog counts / no regression | **PASS** | ContentDB: girls 23, rivals 19, discovery 22, events 62, greetings 8, farewells 5, cafe pool 24, signature pools/events 16/16, ordinary 16, story/final 7 — `catalog_verify_report.txt` |
| SCRIPT/Parse in recheck suite | **PASS** | 0 in content/dating logs (headless quit SIGSEGV after script success — pre-existing teardown noise) |

---

## NPC matrix (Wave R scope)

| Node | Prior QA | After Wave R (this recheck) |
|------|----------|-----------------------------|
| npc_girl_city_umbrella | empty | **OK** girl_city_umbrella |
| npc_girl_city_lanyard | empty | **OK** girl_city_lanyard |
| npc_girl_city_crosswalk | empty | **OK** girl_city_crosswalk |
| npc_girl_cafe_spoon_stack | empty | **OK** girl_cafe_spoon_stack |
| npc_girl_cafe_hot_sauce | empty | **OK** girl_cafe_hot_sauce |
| npc_girl_cafe_sugar_geometry | empty | **OK** girl_cafe_sugar_geometry |
| npc_girl_gym_timer | empty | **OK** girl_gym_timer |
| npc_girl_appearance_coat_check | empty | **OK** girl_appearance_coat_check |
| npc_girl_appearance_mannequin | empty | **OK** girl_appearance_mannequin |
| npc_rival_cafe_menu_holder | empty | **OK** rival_cafe_menu_holder |
| npc_rival_gym_plate_counter | empty | **OK** rival_gym_plate_counter |
| npc_rival_appearance_ringlight | empty | **OK** rival_appearance_ringlight |
| npc_rival_city_thermos | **OK** | **FAIL empty** (regression) |
| npc_rival_city_headphones | **OK** | **FAIL empty** (regression) |

Wave R `before_dump.txt` recorded thermos/headphones OK; current scene no longer has those export values.

---

## Commands executed

```powershell
$godot = "C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe"
$root = "C:\Users\User\Documents\GodotProjects\date_factory"

& $godot --path $root --headless --script res://tmp/m25_r/verify_npc_ids.gd
& $godot --path $root --headless --script res://tmp/m25_qa/npc_id_dump.gd
& $godot --path $root --headless --script res://tmp/m25_qa_recheck/check_thermos_headphones.gd
& $godot --path $root --headless --quit-after 120000 res://world/test/content_data_test.tscn
& $godot --path $root --headless --quit-after 120000 res://game/dating/test/dating_test.tscn
& $godot --path $root --headless --quit-after 30000 res://tmp/m25_qa/m25_catalog_verify.tscn
```

Plus PowerShell `.tscn` text spot-check → `tscn_id_spotcheck.txt`.

---

## Edge cases

1. **Partial fix false confidence** — script that only asserts the previously broken 12 nodes PASSes while the full 14-NPC requirement FAILs.  
2. **Scene edit regression** — IDs that were present before Wave R on thermos/headphones are absent after city_hub edits.

---

## Blocking issues

1. **Critical:** `npc_rival_city_thermos` and `npc_rival_city_headphones` have empty `spawn_id` / `rival_id` (regression vs prior QA + Wave R before-dump).  
2. DoD still unmet for **all 5** new ordinary rivals wired with content IDs.

## Non-blocking (unchanged from prior QA)

1. Screenshot filename/content mismatches (apartment notes, bus stop, lab date plates duplicate).  
2. Headless quit SIGSEGV / RID noise after successful asserts.  
3. Broader pre-M25 ordinary NPC ID gaps (bicycle/chalk/laptop etc.) still empty — outside narrow “new 9 girls” but systemic.

---

## Overall status

**Overall status:** **FAIL**

**Blocking issues:** empty IDs on `rival_city_thermos` + `rival_city_headphones` (2/5 new rivals).

**Non-blocking issues:** prior screenshot evidence quality; teardown noise; other empty pre-M25 NPCs.

**Evidence:** `tmp/m25_qa_recheck/` (`verify_npc_ids.log`, `verify_report.txt`, `npc_id_dump.txt`, `thermos_headphones_check.txt`, `tscn_id_spotcheck.txt`, `content_data_test.log`, `dating_test.log`, `catalog_verify_report.txt`, `disk_catalog_counts.json`).

**Reproduction steps:**

1. Run `verify_npc_ids.gd` → observe PASS / `VERIFY_EXIT 0` for 12 nodes.  
2. Run `npc_id_dump.gd` or open `city_hub.tscn` → observe thermos/headphones empty.  
3. Fix: set `spawn_id` + `RivalActor.rival_id` to `rival_city_thermos` / `rival_city_headphones` (match prior wiring).  
4. Expand verify to all **14** M25 new NPCs; re-run dump + content/dating + catalog.  
5. Re-QA → only then consider READY.

**Orchestrator decision:** **NOT READY** until thermos/headphones IDs are restored and full 9+5 matrix is re-verified.
