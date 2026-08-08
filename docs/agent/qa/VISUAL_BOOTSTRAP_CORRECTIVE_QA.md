# VISUAL BOOTSTRAP CORRECTIVE — Independent QA

**Task ID:** VC-QA / VC-REVIEW  
**Date:** 2026-08-09  
**Branch:** `visual-review/corrective-20260809`  
**Base SHA:** `d9fa8326c8f48851f28aa407324e5599b3a4f459` (`Correct visual bootstrap: donor lighting, real interactables, single-base characters.`)  
**Engine:** Godot 4.7.1 (`C:\Godot\Godot_v4.7.1-stable_win64.exe`), windowed 1920×1080  
**QA worker:** df-qa-worker (independent; did not trust implementation evidence alone)

## Overall status

**NOT READY**

Critical player-visible failure: modular character presentation does not show readable appearance differences. Variant lineups and in-world NPCs render as identical underwear base meshes; accessory/prop meshes sit at feet as colored boxes. Automated presentation self-test previously logged PASS, but opened PNGs contradict “modular differences readable.”

Travel, interactables with CollisionShape3D, donor refs, and women_modular/PACK_019 runtime refs are PASS.

## Criteria table

| # | Criterion | Status | Evidence | Reproduction |
|---|-----------|--------|----------|--------------|
| 1 | Normal project / scene load for captures | **PASS** | All location+char capture scripts exit 0; 31 PNGs 1920×1080 | `Godot --path . --windowed --resolution 1920x1080 -s res://tmp/vc_qa/capture_locations.gd` |
| 2 | Travel apartment ↔ city ↔ cafe | **PASS** | `verify_travel.log` travel rc=0 each hop | `... -s res://tmp/vc_qa/verify_travel_interactables.gd` |
| 3 | Mine / lab / production unlock via `restore_stage` | **PASS** | STAGE_3 mine, STAGE_5+scientist lab, STAGE_6 production | same verify script |
| 4 | Interactables exist + CollisionShape3D (not floating empty Areas) | **PASS** | DayAdvance, DateVenue, ProgressionSelfAssessment, cafe DateVenue, SalaryStation, FirstCloneMachine, CloneTerminal, GlobalExpansionTerminal all `shape=true` | verify log |
| 5 | Control return / repeated cafe travel | **PASS** | repeated cafe travel PASS; STAGE_1 blocks production | verify log |
| 6 | Save/load smoke | **PASS** *(WARN)* | MANUAL_1 save/load ok; engine WARN `saved player pose invalid; keeping spawn_default` | verify log |
| 7 | Donor runtime refs = 0 | **PASS** | runtime + static scan 0 | verify log |
| 8 | women_modular / PACK_019 runtime refs = 0 | **PASS** | scan 0 under world/characters/data/game/ui (+ assets excl. women_modular folder) | verify log |
| 9 | No critical Failed to load / missing resources on travel | **PASS** | No `Failed to load` / missing resource during travel; only quit-time RID leak noise | `verify_travel_stdout.txt` |
| 10 | Character presentation self-test log | **PASS** *(script)* / **FAIL** *(visual)* | `tmp/vc_rc/character_presentation.log`: `ALL PASS (691)`; opened variant PNGs show no modular clothing/hair differences | re-open `_review/visual_corrective/chars_*_variants.png` |
| 11 | Cafe empty via QA fixture only (NpcSpawns hidden) | **PASS** | capture log `QA_FIXTURE hide NpcSpawns`; empty shots have no NPCs | capture_locations.log + opened cafe_empty_*.png |
| 12 | Cafe production shows NPCs | **PASS** *(presence)* / **FAIL** *(presentation)* | NPCs present; all underwear base + green pedestals | cafe_production_*.png |
| 13 | Screenshot set complete (exact names) | **PASS** | 31/31 PNGs published under `_review/visual_corrective/` | inventory below |
| 14 | Modular variants ≥5 side-by-side, differences readable | **FAIL** | 6 male + 6 female profiles spawned; meshes look identical underwear; colored boxes at feet | chars_male_variants.png, chars_female_variants.png |
| 15 | City visual quality (no void / obvious broken lights) | **WARNING** | Night street readable; greybox buildings; floating pink/red light slab on cafe approach; translucent blue volumes on street | city_*.png |
| 16 | Edge: locked late location at STAGE_1 | **PASS** | `edge_locked_production_rc=1` | verify log |

## Blocking issues

1. **Character modular presentation unreadable (critical).** Studio and venue NPCs show bald underwear bases only. Variant lineups do not show distinct hair/top/bottom/shoes. Colored primitive boxes at feet indicate slot/prop attach failure visible to player. Undermines corrective commit’s “single-base characters” player result.
2. **In-world NPC presentation matches the same failure** (city + cafe production), so it is not limited to the studio QA fixture.

## Non-blocking issues

1. City still mixes detailed brick facades with large greybox blocks; night sky is pure black.
2. `city_cafe_approach`: floating pink/red glowing rectangular light/sign.
3. City street: large translucent blue volumes (likely transition debug/Area visuals).
4. Save restore: `saved player pose invalid; keeping spawn_default` warning (load still succeeds).
5. Capture script quit leaks RID/resources (engine teardown noise only; not travel-time failures).
6. Cafe lighting is very high-contrast / dark corners (readable enough for venue review).

## Screenshot inventory (opened PNG descriptions)

Committed copies: `_review/visual_corrective/<name>.png` (source work dir `tmp/visual_corrective/`).

### CITY

| File | Opened content |
|------|----------------|
| `city_spawn_forward.png` | Night city street looking past lit brick storefront (pink awning), outdoor bench; bald underwear NPCs on green pedestals along street; greybox wall mid-frame. |
| `city_main_street_left.png` | Looking down street between greybox shops with cyan/white wall panels; muscular male underwear NPC left; globe streetlamps; large translucent blue volume mid-street; brick towers far. |
| `city_intersection.png` | Wide street view; female underwear NPC left; several male underwear NPCs right sidewalk; mint/tan storefronts; distant blue glow. |
| `city_cafe_approach.png` | Brick cafe facade + outdoor table/stool; **floating pink/red glowing slab + vertical glow** in street; no NPCs in frame. |

### ROOM (apartment)

| File | Opened content |
|------|----------------|
| `room_spawn.png` | Compact low-poly studio: bed+blue curtains, round table with two plates, dresser; warm light, no void. |
| `room_main_area.png` | Kitchenette (sink/stove) + bed + table + dresser; coherent apartment. |
| `room_wide_a.png` | High angle: fridge/cabinets/sink/stove, bed, table, dresser; furniture grounded. |
| `room_wide_b.png` | Wide corner including door, kitchen wall, bed/window; same donor-style room. |

### CAFE VENUE_ONLY (NpcSpawns hidden via QA fixture)

| File | Opened content |
|------|----------------|
| `cafe_empty_entrance.png` | Dim Japanese cafe: red chairs, lanterns, bamboo, eye banner; **no NPCs**. |
| `cafe_empty_center.png` | Table + dango on red runner, red armchair; empty of NPCs. |
| `cafe_empty_date_view.png` | Date seating + cherry blossom + sushi sign; empty of NPCs. |
| `cafe_empty_wide.png` | Elevated wide cafe interior; empty of NPCs. |

### CAFE PRODUCTION

| File | Opened content |
|------|----------------|
| `cafe_production_entrance.png` | Same cafe entrance with **multiple underwear NPCs** (+ green pedestals). |
| `cafe_production_center.png` | Center seating; muscular male underwear NPC right. |
| `cafe_production_date_view.png` | Date view with several underwear NPCs + blossom tree. |

### MINE

| File | Opened content |
|------|----------------|
| `mine_wide.png` | Industrial low-poly hall, orange wall stripe, bed/machine left, blue console+stool, crates/gear; sci-fi pack look (matches `salary_mine.tscn` load in log). |
| `mine_salary.png` | Close view: blue salary console, grey stool, large gear prop, orange stripe walls. |

### LAB

| File | Opened content |
|------|----------------|
| `lab_entrance.png` | Dark cyan lab aisle, white desks, glowing wall panels, crate, shelves; flat purple-grey band top of frame. |
| `lab_wide.png` | Darker wide aisle between glowing partitions; chair+terminal far; dim. |
| `lab_clone_core.png` | Cyan-lit crate + translucent wall pods + white desk/chair. |
| `lab_terminal.png` | White curved desk+chair, glowing blue terminal, shelves; grounded. |

### LATE (production_area)

| File | Opened content |
|------|----------------|
| `late_entrance.png` | Purple/orange-stripe production hall; white/black global terminal center; crates; floating text. |
| `late_wide.png` | Wide production view; central terminal; Cyrillic **«Охват Земли: 0»**; machinery/crates. |
| `late_terminal.png` | Close terminal console + blank monitor; duplicate «Охват Земли: 0» labels. |

### CHARACTERS

| File | Opened content |
|------|----------------|
| `chars_male_base.png` | Single muscular bald male in dark briefs on grey studio floor; teal/yellow prop box at feet. |
| `chars_female_base.png` | Single bald athletic female in black bikini underwear; green/black boxes at feet. |
| `chars_male_variants.png` | **Six identical** underwear males in a row; only foot-box colors differ — **modular differences NOT readable**. |
| `chars_female_variants.png` | **Six identical** underwear females in a row; colored platforms/boxes differ — **modular differences NOT readable**. |
| `chars_mixed_group.png` | Six mixed male/female underwear bases; same presentation failure. |
| `chars_city_example.png` | Night city sidewalk; underwear NPCs on green pedestals near streetlamps/brick bg. |
| `chars_cafe_example.png` | Cafe interior with multiple underwear NPCs among red chairs/tables. |

**Screenshot count:** 31

## Engine logs / journals

| Path | Role |
|------|------|
| `tmp/vc_qa/capture_locations.log` | Location capture journal |
| `tmp/vc_qa/capture_locations_stdout.txt` | Raw Godot stdout (locations) |
| `tmp/vc_qa/capture_chars.log` | Character capture journal |
| `tmp/vc_qa/capture_chars_stdout.txt` | Raw Godot stdout (chars) |
| `tmp/vc_qa/verify_travel.log` | Travel/interactable/refs journal |
| `tmp/vc_qa/verify_travel_stdout.txt` | Raw Godot stdout (verify) |
| `tmp/vc_qa/verify_journal.txt` | Same verify lines |
| `tmp/vc_rc/character_presentation.log` | Prior presentation self-test: `ALL PASS (691)` |

## Refs checks

| Check | Result |
|-------|--------|
| Runtime `scene_file_path` donor leaks on loaded locations | **0** |
| Static production text donor (`date_factory_legacy`, `../date_factory`) | **0** |
| women_modular / PACK_019 runtime refs (world/characters/data/game/ui + assets excl. pack folder) | **0** |

## Commands executed

```text
git fetch; git checkout -B visual-review/corrective-20260809 d9fa832
C:\Godot\Godot_v4.7.1-stable_win64.exe --path . --windowed --resolution 1920x1080 -s res://tmp/vc_qa/capture_locations.gd
C:\Godot\Godot_v4.7.1-stable_win64.exe --path . --windowed --resolution 1920x1080 -s res://tmp/vc_qa/capture_chars.gd
C:\Godot\Godot_v4.7.1-stable_win64.exe --path . --windowed --resolution 1920x1080 -s res://tmp/vc_qa/verify_travel_interactables.gd
# copy PNGs → _review/visual_corrective/
```

## Unmet criteria

- Readable modular differences for `chars_male_variants` / `chars_female_variants` (≥5 profiles side-by-side with visible hair/clothing variance).
- Production NPC presentation in city/cafe matching intended modular outfits (not underwear + foot props).
- (Non-blocking) city_cafe_approach floating light; city greybox + blue volume polish.

## Recommendation

**NOT READY**

Do not treat the corrective visual bootstrap as player-ready until character slot visuals are fixed and re-captured. Locations, travel, interactable collision, and zero donor/women_modular runtime refs are in good shape and can stay; character presentation is the blocker.

## Reproduction steps (blocker)

1. Checkout `d9fa832` / branch `visual-review/corrective-20260809`.
2. Run `capture_chars.gd` as above (or open `_review/visual_corrective/chars_male_variants.png` and `chars_female_variants.png`).
3. Observe six near-identical underwear bodies; colored boxes at feet; no distinct modular outfits.
4. Open `cafe_production_entrance.png` / `chars_city_example.png` — same underwear NPCs in venues.
