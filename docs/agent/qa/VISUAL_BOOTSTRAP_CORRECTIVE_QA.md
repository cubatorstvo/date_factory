# VISUAL BOOTSTRAP CORRECTIVE — Independent QA (RECHECK)

**Task ID:** VC-QA-RECHECK  
**Date:** 2026-08-09  
**Branch:** `visual-review/corrective-20260809`  
**Main SHA (fix):** `b59c3c9b6cf6c91a5b9d2bf567afc686306094f3` — *Fix modular character bone attachments so outfit placeholders sit on the body.*  
**Review tip (pre-PNG commit):** merge of main into review containing `b59c3c9`  
**Prior FAIL base:** `d9fa8326c8f48851f28aa407324e5599b3a4f459`  
**Engine:** Godot 4.7.1 (`C:\Godot\Godot_v4.7.1-stable_win64.exe`), windowed 1920×1080  
**QA worker:** df-qa-worker (independent recheck; own captures + opened PNGs)

## Overall status

**READY**

Prior critical blocker (modular parts piled at feet; variant lineups unreadable) is cleared after `b59c3c9` (`BoneAttachment` `external_skeleton` → `../Body/Armature/Skeleton3D`). Fresh 1920×1080 captures show hair/top/bottom placeholders on head/chest/hips for ≥6 male and ≥6 female profiles. Presentation self-test: **ALL PASS (902)**.

Locations / travel / interactables / donor + women_modular ref checks from the prior VC-QA pass remain accepted (not re-failed). Non-blocking city polish and placeholder-art caveats remain.

## Criteria table

| # | Criterion | Status | Evidence | Reproduction |
|---|-----------|--------|----------|--------------|
| 1 | Normal project / scene load for captures | **PASS** | Char + cafe production captures exit 0; PNGs 1920×1080 | `Godot ... -s res://tmp/vc_qa/capture_chars.gd` |
| 2 | Travel apartment ↔ city ↔ cafe | **PASS** *(prior)* | Prior `verify_travel.log` travel rc=0 | prior VC-QA |
| 3 | Mine / lab / production unlock via `restore_stage` | **PASS** *(prior)* | Prior verify stages | prior VC-QA |
| 4 | Interactables + CollisionShape3D | **PASS** *(prior)* | Prior verify shape=true | prior VC-QA |
| 5 | Control return / repeated cafe travel | **PASS** *(prior)* | Prior verify | prior VC-QA |
| 6 | Save/load smoke | **PASS** *(WARN, prior)* | Prior MANUAL_1; pose invalid warning | prior VC-QA |
| 7 | Donor runtime refs = 0 | **PASS** *(prior)* | Prior scan 0 | prior VC-QA |
| 8 | women_modular / PACK_019 runtime refs = 0 | **PASS** *(prior)* | Prior scan 0 | prior VC-QA |
| 9 | No critical Failed to load on travel | **PASS** *(prior)* | Prior stdout | prior VC-QA |
| 10 | Character presentation self-test | **PASS** | `VC_CHARS_PRESENTATION_TEST: ALL PASS (902)`; `tmp/vc_qa/presentation_test_recheck.txt` | `Godot ... res://characters/test/character_presentation_test.tscn` |
| 11 | Cafe empty via QA fixture only | **PASS** *(prior)* | Prior empty shots | prior VC-QA |
| 12 | Cafe production shows NPCs with parts on body | **PASS** | Opened `cafe_production_*.png` — hair/tops/bottoms at head/torso/hips; NPCs present | recheck cafe capture |
| 13 | Screenshot set complete (exact names) | **PASS** | 31/31 under `_review/visual_corrective/`; 10 char/cafe PNGs refreshed | inventory |
| 14 | Modular variants ≥5 side-by-side, differences readable | **PASS** | Opened male/female variant PNGs: 6+6 distinct hair/top/bottom combos on body | `chars_male_variants.png`, `chars_female_variants.png` |
| 15 | City visual quality | **WARNING** | Night street readable; greybox / black sky / prior floating light notes unchanged for non-refreshed city_*.png | prior city_*.png |
| 16 | Edge: locked late location at STAGE_1 | **PASS** *(prior)* | Prior `edge_locked_production_rc=1` | prior VC-QA |

## Blocking issues

*None.* Previous critical modular-attachment FAIL is resolved on main `b59c3c9` and confirmed by recheck screenshots + presentation test.

## Non-blocking issues

1. Outfit slots still use **colored primitive placeholders** (not final clothing art) — intentional for modular POC; do not block readiness per recheck scope.
2. Thin **black shoe/foot placeholder** at left foot is expected shoe-slot attach (not the old all-parts-at-feet pile).
3. Animated cafe poses can make rigid placeholder boxes look slightly offset / clipping while still bone-attached at correct body height.
4. City still mixes greybox blocks; night sky pure black; prior floating pink light on `city_cafe_approach` (not re-captured this recheck).
5. Save restore warning: `saved player pose invalid; keeping spawn_default` (prior).
6. Capture script quit RID/resource teardown noise only.

## Screenshot inventory (opened PNG descriptions — recheck)

Committed copies: `_review/visual_corrective/<name>.png` (work dir `tmp/visual_corrective/`).

### CHARACTERS (refreshed 2026-08-09 recheck)

| File | Opened content / verdict |
|------|--------------------------|
| `chars_male_base.png` | Single male base; **tan cylinder hair on head**, **teal box on chest**, **dark apron on hips**, black shoe box at left foot. Parts ON body. |
| `chars_female_base.png` | Single female base; **black sphere on head**, **green cube on chest**, **purple plane on hip**, black shoe box at left foot. Parts ON body. |
| `chars_male_variants.png` | **Six** males side-by-side; distinct hair (tan cyl / flat brown / red slab / purple cubes / grey-blue) + tops (teal/blue/white/orange/red/grey) + bottoms (dark/tan/orange/white/grey/blue). **Differences readable. PASS.** |
| `chars_female_variants.png` | **Six** females; distinct hair (black sphere / yellow hat-cyl / red hair mesh / purple box / brown slab) + tops (green/teal/grey/white/orange/navy) + bottoms (purple/black drop/blue/orange/white pill/tan). **Differences readable. PASS.** |
| `chars_mixed_group.png` | Six mixed profiles; hair/tops/bottoms on body with distinct color combos. PASS. |
| `chars_city_example.png` | Night city; NPCs with green torso / purple hip / head pieces on body (not piled at feet). PASS for attach. |
| `chars_cafe_example.png` | Cafe NPCs with yellow hair cylinders / green tops / purple bottoms at body heights; black shoe boxes at feet. PASS for attach. |

### CAFE PRODUCTION (refreshed)

| File | Opened content / verdict |
|------|--------------------------|
| `cafe_production_entrance.png` | Multiple NPCs; yellow hair on heads, green tops on torsos, purple bottoms on hips. PASS. |
| `cafe_production_center.png` | Male near dango table; hair/top at head/chest height during pose (rigid placeholders can look offset). Attach height OK vs prior feet pile. |
| `cafe_production_date_view.png` | Date seating + NPCs; green torso boxes and distinct head pieces visible; dark venue. PASS for attach. |

### Unchanged from prior VC-QA (not re-captured)

CITY (`city_*`), ROOM (`room_*`), CAFE EMPTY (`cafe_empty_*`), MINE, LAB, LATE — prior PASS descriptions still apply; city WARNING polish remains.

**Screenshot count:** 31 (10 refreshed this recheck)

## Engine logs / journals (recheck)

| Path | Role |
|------|------|
| `tmp/vc_qa/capture_chars_stdout_recheck.txt` | Raw Godot stdout (chars recheck) |
| `tmp/vc_qa/capture_chars.log` | Character capture journal |
| `tmp/vc_qa/capture_cafe_production_stdout.txt` | Raw Godot stdout (cafe production) |
| `tmp/vc_qa/capture_cafe_production.log` | Cafe production journal |
| `tmp/vc_qa/presentation_test_recheck.txt` | Presentation self-test: `ALL PASS (902)` |
| `docs/agent/qa/evidence/vc_chars_fix/after_lineup_variants.png` | Presentation-test lineup evidence |
| `docs/agent/qa/evidence/vc_chars_fix/after_slot_heights.json` | Slot height metrics |

## Commands executed (recheck)

```text
git checkout main; git pull origin main
# main HEAD = b59c3c9
git stash push -u -m "VC-QA-RECHECK stash unrelated WIP..."
git checkout visual-review/corrective-20260809
git merge main -m "Merge main into visual-review/corrective-20260809 for character modular fix recheck."
C:\Godot\Godot_v4.7.1-stable_win64.exe --path . --windowed --resolution 1920x1080 -s res://tmp/vc_qa/capture_chars.gd
C:\Godot\Godot_v4.7.1-stable_win64.exe --path . --windowed --resolution 1920x1080 -s res://tmp/vc_qa/capture_cafe_production.gd
C:\Godot\Godot_v4.7.1-stable_win64.exe --path . --windowed --resolution 1920x1080 res://characters/test/character_presentation_test.tscn
# copy refreshed PNGs → _review/visual_corrective/
```

## Unmet criteria

*None blocking.* Remaining items are non-blocking polish (city greybox/lights, placeholder clothing art, save pose warning).

## Recommendation

**READY**

Character modular bone-attachment fix on main `b59c3c9` is verified by independent re-capture and opened PNGs. Review branch screenshots under `_review/visual_corrective/` updated for chars_* and cafe_production_*. Prior location/travel/ref PASS results stand.

## Reproduction steps (verify fix)

1. Checkout `visual-review/corrective-20260809` (after recheck push) or main `b59c3c9`.
2. Open `_review/visual_corrective/chars_male_variants.png` and `chars_female_variants.png`.
3. Confirm ≥5 profiles with hair on head, tops on chest, bottoms on hips; color/shape differences readable.
4. Run presentation test scene → expect `VC_CHARS_PRESENTATION_TEST: ALL PASS (902)`.
