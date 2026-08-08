# M25_QA — MODULE 25 Independent QA

**Task:** M25 Content Completion QA  
**Module:** 25 — Content Completion  
**Date:** 2026-08-08  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  
**Evidence:** `tmp/m25_qa/` (+ opened prior capture images under `tmp/m25_l/`, `tmp/m25_m/`, `tmp/m25_n/`)  
**DoD:** `docs/modules/MODULE_25_CONTENT_COMPLETION.md` §114 + `docs/agent/ACCEPTANCE.md` + `docs/content/MANUAL_CONTENT_COMPLETE.md`

## Verdict

**FAIL** → recommend **NOT READY**

Catalog counts, 4×4 ordinary matrix, Media priority, flavor/gag node counts, upgrade visual tiers, schema v1, and headless regressions all PASS independently. **Critical route broken:** all **9 new GirlActors** and **3/5 new RivalActors** are physically placed but ship with **empty `spawn_id` / `girl_id` / `rival_id`**, so discovery/interact cannot bind to content IDs. Executor wave E1/H reports claimed wired IDs; re-running the same verify scripts against current scenes FAILS.

---

## 1. Summary

| Area | Result |
|------|--------|
| Disk/catalog counts (23/16/19/22/62/24/16/8/5) | PASS |
| Ordinary 4×4 matrix | PASS (`content_data_test` ALL PASS 649 + ContentDB inspect) |
| 9 GirlActors + 5 RivalActors placement | **FAIL** — nodes exist; **IDs empty** (except 2 rivals) |
| Media `CANDIDATE_PRIORITY` | PASS — first 7 unchanged, +9 Spec order |
| Flavor ≥24 + Spec distribution; gags ≥12; no GS mutation | PASS (flavor); gag anchors PASS with screenshot WARNINGs |
| UpgradeLevelVisual lab 15 / production 9 | PASS |
| `SAVE_SCHEMA_VERSION == 1` + old14 compat in save suite | PASS (`save_system_self_test` ALL PASS 138) |
| Headless regressions listed | PASS (ALL PASS lines; 0 SCRIPT/Parse) |
| No MODULE26 balance / no new systems | PASS |
| Screenshots vs filenames | Mixed — several PASS; lab plates duplicate FAIL; bus stop weak |
| Manual city/cafe/gym/appearance interact sample | **FAIL / unmet** — blocked by empty girl_id |

---

## 2. Criteria

| Criterion | Status | Evidence | Reproduction |
|-----------|--------|----------|--------------|
| Girls exact 23 | PASS | Disk 23; catalog path mentions 23; ContentDB `list_girls` 23 | `tmp/m25_qa/disk_catalog_counts.json`, `catalog_verify_report.txt` |
| Ordinary exact 16 | PASS | ContentDB ordinary=16 | `catalog_verify_report.txt` |
| Story/final remain 7 | PASS | story/final=7 | same |
| 4×4 unique pairs complete | PASS | pairs=16; `content_data_self_test` `_test_module25_ordinary_matrix` in suite ALL PASS 649 | `content_data_test.log` |
| 9 new ordinary girls exist | PASS | all 9 `try_get_girl` OK | `catalog_verify_report.txt` |
| Discovery exact 22 | PASS | disk+catalog+ContentDB 22 | counts + catalog verify |
| Rivals exact 19 | PASS | 19 | same |
| Cafe common 24 | PASS | pool `event_ids` size 24 | catalog verify + pool tres |
| Signature pools/events 16/16 | PASS | 16/16 | catalog verify |
| Greetings 8 / farewells 5 | PASS | 8/5 | catalog verify |
| Dating events ≥62 | PASS | 62 | disk + ContentDB |
| Media first 7 + append 9 Spec order | PASS | `MediaContent.CANDIDATE_PRIORITY` matches §59 | `game/media/media_content.gd` + catalog verify |
| 9 GirlActors placed & wired | **FAIL** | Markers+GirlActor+collision exist; **`spawn_id`/`girl_id` empty for all 9** | `tmp/m25_qa/npc_id_dump.txt`, `e1_rerun_report.txt`, `h_rerun_report.txt` |
| 5 RivalActors placed & wired | **FAIL** | thermos+headphones OK; **menu_holder / plate_counter / ringlight empty IDs** | `npc_id_dump.txt`, `i_rerun_report.txt` |
| Flavor ≥24 + per-location mins | PASS | 5/5/3/2/3/2/2/1/1 = 24 | indep verify + scene Flavor\* counts |
| Flavor no GameState mutation | PASS | `flavor_interactable.gd` only mentions GameState in comment; interact → HUD notify only | script read |
| Gags ≥12 present | PASS | 12 gag anchors found via headless path/name checks | indep verify; wave L/M/N reports |
| Lab local UpgradeLevelVisual 0..5 / 15 tiers | PASS | 15 ULV under `UpgradeVisuals`; mins 1..5 + Level0 labels | indep verify |
| Production global tiers 0..3 / 9 | PASS | 9 ULV; mins 1..3 | indep verify |
| Formulas unchanged / presentation-only | PASS | ULV has no spend/set upgrade; no MODULE26 markers in game code | script + grep |
| `SAVE_SCHEMA_VERSION == 1` | PASS | `SaveTypes.SAVE_SCHEMA_VERSION = 1` | `persistence/save_types.gd` + catalog verify |
| old14 save compat | PASS | `_test_module25_old14_save_compat` in suite; ALL PASS (138) | `save_system_self_test.gd` + `.log` |
| Headless regressions | PASS | See §3 | `tmp/m25_qa/*_test.log` |
| No SCRIPT ERROR / Parse Error | PASS | grep count 0 across suite logs | logs |
| No MODULE26 balance ahead | PASS | no MODULE26 module doc; no anti-grind/balance markers in game gd | filesystem + grep |
| Screenshots match claimed content | WARNING / partial FAIL | See §4 | opened images |
| Manual walkthrough sample 2+ new girls | **FAIL** | Not executable for interact: empty `girl_id` | NPC dump |

### Edge cases exercised

1. **Empty content IDs on new ordinary NPCs** — physical spawn present, binding broken (`girl_id=""` / `spawn_id=""`).  
2. **Screenshot filename/content mismatch** — `laboratory_date_plates.png` byte-identical to `laboratory_ready_sign.png` (no plates `01`..`10` evidence).

---

## 3. Commands executed

```powershell
$godot = "C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe"
$root = "C:\Users\User\Documents\GodotProjects\date_factory"

# Disk/catalog counts → tmp/m25_qa/disk_catalog_counts.json

# Headless regressions → tmp/m25_qa/<name>.log
& $godot --path $root --headless --quit-after 120000 res://world/test/content_data_test.tscn
& $godot --path $root --headless --quit-after 120000 res://game/dating/test/dating_test.tscn
& $godot --path $root --headless --quit-after 90000  res://game/media/test/media_test.tscn
& $godot --path $root --headless --quit-after 120000 res://persistence/test/save_system_self_test.tscn
& $godot --path $root --headless --quit-after 90000  res://game/state/test/game_state_save_self_test.tscn
& $godot --path $root --headless --quit-after 90000  res://game/clone_incremental/test/clone_incremental_test.tscn
& $godot --path $root --headless --quit-after 90000  res://world/test/world_save_pose_test.tscn
& $godot --path $root --headless --quit-after 90000  res://game/story/test/story_test.tscn
& $godot --path $root --headless --quit-after 90000  res://game/final_date/test/final_date_test.tscn

# Indep catalog/media/schema
& $godot --path $root --headless --quit-after 30000 res://tmp/m25_qa/m25_catalog_verify.tscn

# Indep NPC ID dump + re-run executor spawn verifies
& $godot --path $root --headless --script res://tmp/m25_qa/npc_id_dump.gd
& $godot --path $root --headless --script res://tmp/m25_e1/verify_spawns.gd
& $godot --path $root --headless --script res://tmp/m25_h/verify_spawns.gd
& $godot --path $root --headless --script res://tmp/m25_i/verify_spawns.gd
```

### Regression table (independent)

| Test | ALL PASS | SCRIPT/Parse |
|------|----------|--------------|
| content_data_test | ALL PASS (649) | 0 |
| dating_test | ALL PASS (270) | 0 |
| media_test | ALL PASS (146) | 0 |
| save_system_self_test | ALL PASS (138) | 0 |
| game_state_save_self_test | ALL PASS (88) | 0 |
| clone_incremental_test | ALL PASS (110) | 0 |
| world_save_pose_test | ALL PASS (28) | 0 |
| story_test | ALL PASS (85) | 0 |
| final_date_test | ALL PASS (78) | 0 |

Notes:
- Expected intentional `ERROR:` noise in domain/content tests (missing girl fixture, reject restore paths).
- Headless quit may SIGSEGV / RID leak after ALL PASS (pre-existing engine teardown class); not treated as product FAIL when ALL PASS printed.
- `content_data_self_test.gd` includes `_test_module25_ordinary_matrix` / completeness (drives part of the 649).

---

## 4. Screenshots — paths + factual content (QA opened each)

| File | Claimed | Actual content (opened) | Match |
|------|---------|-------------------------|-------|
| `tmp/m25_l/apartment_planning_notes.png` | Apartment planning notes gag | Low-poly room; female NPC (blonde/white tee/orange pants); pedestal labeled **«Зеркало»**; glitchy black/white overlay near pedestal. **No ПЛАН A/B/C notes visible** | **FAIL / mismatch** |
| `tmp/m25_l/city_bus_stop.png` | City bus-stop gag | Abstract red/tan/blue-gray block stack; **no readable «Ожидание…» text / bus stop prop** | **FAIL / weak** |
| `tmp/m25_l/city_center_arrows.png` | Conflicting center arrows | City hub: **«ГОРОД»**, yellow **«← ЦЕНТР»** / **«ЦЕНТР →»**, cafe/urn labels; 2 female + 2 male NPCs visible | PASS (gag + NPC presence) |
| `tmp/m25_m/cafe_last_cake.png` | Last cake gag | Blue stand + pink cake cylinder; red label **«последний»** | PASS |
| `tmp/m25_m/cafe_stabilized_table.png` | Stabilized table leg | Brown table; small white rect under top near leg (folded-menu gag) | PASS |
| `tmp/m25_m/gym_tiny_dumbbell.png` | Tiny dumbbell gag | Rack shelves; tiny black dumbbell on lower shelf | PASS |
| `tmp/m25_m/appearance_mannequin_negotiation.png` | Mannequin negotiation gag | Two blue pill mannequins at brown table; label **«ПЕРЕГОВОРЫ»**; female figure in foreground | PASS |
| `tmp/m25_n/laboratory_ready_sign.png` | Lab ready sign | Lab view: **«ЛАБОРАТОРИЯ»**, **«ЧЕЛОВЕК ГОТОВ»**, terminal/calibration labels | PASS |
| `tmp/m25_n/laboratory_date_plates.png` | Lab date plates 01..10 | **Byte-identical to `laboratory_ready_sign.png`**; no plate numbers | **FAIL / duplicate** |
| `tmp/m25_n/production_shipping_board.png` | Shipping board gag | Panel **«ОТГРУЗКА»** with **«ЧЕЛОВЕК»** lines; HUD **«Охват Земли: 0»** | PASS with WARNING (line text not clearly full «ЧЕЛОВЕК — 1 ШТ.» set) |
| `tmp/m25_n/final_napkin_holder.png` | Final napkin holder | Final table + chairs; label **«салфетки»** / **«Стол»** | PASS |

Copies of key images also under `tmp/m25_qa/` for apartment/cake/lab ready.

---

## 5. NPC wiring detail (blocking)

Independent instantiate dump (`tmp/m25_qa/npc_id_dump.txt`):

| Node | spawn_id | girl_id / rival_id |
|------|----------|--------------------|
| npc_girl_city_umbrella | empty | empty |
| npc_girl_city_lanyard | empty | empty |
| npc_girl_city_crosswalk | empty | empty |
| npc_girl_cafe_spoon_stack | empty | empty |
| npc_girl_cafe_hot_sauce | empty | empty |
| npc_girl_cafe_sugar_geometry | empty | empty |
| npc_girl_gym_timer | empty | empty |
| npc_girl_appearance_coat_check | empty | empty |
| npc_girl_appearance_mannequin | empty | empty |
| npc_rival_city_thermos | rival_city_thermos | rival_city_thermos |
| npc_rival_city_headphones | rival_city_headphones | rival_city_headphones |
| npc_rival_cafe_menu_holder | empty | empty |
| npc_rival_gym_plate_counter | empty | empty |
| npc_rival_appearance_ringlight | empty | empty |

Re-ran executor scripts → current FAIL (contrast with archived PASS reports in `tmp/m25_e1/`, `tmp/m25_h/`, `tmp/m25_i/`). Likely regression from later scene edits (flavor/gag waves) stripping exported IDs / making editable instances without re-setting exports.

Reference wired pattern still present for some older NPCs (e.g. `girl_public_sculpture`, `girl_cafe_receipt_notes`, `girl_appearance_flash`).

---

## 6. Non-blocking issues

1. **Screenshot evidence quality (WARNING/FAIL):** apartment planning notes + city bus stop filenames do not match opened pixels; lab date plates is a duplicate file.  
2. **Exit-time RID/ObjectDB / occasional quit SIGSEGV** after ALL PASS — pre-existing headless teardown noise.  
3. **Broader pre-M25 ordinary NPC ID gaps** observed (e.g. bicycle/chalk/laptop also empty in dump) — out of narrow “new 9” scope but suggests systemic scene export drift; Orchestrator should decide whether to expand fix.  
4. **Manual F5 interact walkthrough** not completed (blocked by ID FAIL; city arrow shot shows physical NPCs only).

---

## 7. Blocking issues

1. **Critical:** All 9 new ordinary `GirlActor`s lack `girl_id` (+ markers lack `spawn_id`) → discovery/interact route for MODULE25 ordinary content is not production-ready.  
2. **Critical:** 3 of 5 new ordinary rivals (`cafe_menu_holder`, `gym_plate_counter`, `appearance_ringlight`) lack `rival_id`/`spawn_id`.  
3. DoD §114 items requiring physical production placement that is **validly bound to content IDs** are unmet.

---

## 8. Unmet criteria (vs §114 / ACCEPTANCE)

- [ ] each new girl/rival has valid fixed production placement **with content IDs**  
- [ ] manual content walkthrough sampling new girls interactable  
- [ ] screenshot evidence integrity for all claimed gag/tier captures  

Met: catalog totals, matrix, dating volume, media order, flavor/gag counts, upgrade visuals, schema v1, regressions, no MODULE26.

---

## 9. Overall status

**Overall status:** **FAIL**

**Blocking issues:** empty `girl_id`/`spawn_id` on 9 new girls; empty IDs on 3/5 new rivals; interact walkthrough blocked.

**Non-blocking issues:** screenshot filename mismatches / lab plates duplicate; headless teardown noise; possible pre-M25 NPC export drift.

**Evidence:** `tmp/m25_qa/` (`disk_catalog_counts.json`, `catalog_verify_report.txt`, `npc_id_dump.txt`, `*_test.log`, `e1_rerun_report.txt`, `h_rerun_report.txt`, `i_rerun_report.txt`, `regression_parsed.txt`) + opened `tmp/m25_l|m|n/*.png`.

**Reproduction steps:**

1. Run catalog verify scene → expect all OK counts/media/schema.  
2. Run `npc_id_dump.gd` or `tmp/m25_e1/verify_spawns.gd` → observe FAIL empty IDs for new girls.  
3. Optionally open city_hub/cafe/gym/appearance in editor and inspect `NpcSpawns/npc_girl_*` exports.  
4. Fix: set `NpcSpawnPoint.spawn_id` + `GirlActor.girl_id` / `RivalActor.rival_id` to matching content IDs (and `npc_kind`) for all new nodes; re-run E1/H/I verifies + sample F5 interact.  
5. Re-capture mismatched screenshots (apartment notes, bus stop, lab date plates).

**Orchestrator decision:** **NOT READY** until NPC ID wiring is fixed and re-QA’d on interact path.

---

## 10. Wave R recheck (2026-08-08)

Full independent recheck: `docs/agent/qa/M25_QA_RECHECK.md`  
Evidence: `tmp/m25_qa_recheck/`

| Item | Result |
|------|--------|
| Prior 12 empty nodes (9 girls + 3 rivals) | **PASS** — wired; `verify_npc_ids.gd` VERIFY_EXIT 0 |
| Full 9 girls + 5 rivals | **FAIL** — thermos + headphones now empty (regression) |
| content_data_test / dating_test | PASS (649 / 270) |
| Catalog counts | PASS — no regression |
| **Recheck verdict** | **FAIL / NOT READY** |
