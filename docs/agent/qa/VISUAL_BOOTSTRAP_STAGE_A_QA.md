# VISUAL BOOTSTRAP STAGE A — Independent QA

**Task:** Capture 1920×1080 overview PNGs of donor scenes without modifying donor  
**Date:** 2026-08-08  
**QA agent:** df-qa-worker (independent capture + visual verification)

## Overall status

**PASS** (Stage A only)

All 22 required filenames exist under `tmp/visual_bootstrap_review/legacy/`, are 1920×1080, and have non-trivial file sizes. Donor `date_factory_legacy` remained clean (git status clean). Live gameplay scenes were not modified.

---

## Criteria

| Criterion | Status | Evidence |
|---|---|---|
| Donor read-only | **PASS** | `git -C date_factory_legacy status --porcelain` empty after work |
| Disposable mirror under `tmp/vb_legacy_capture_proj/` | **PASS** | Project + mirrored scenes/assets + capture runner |
| Window / viewport 1920×1080 | **PASS** | `project.godot` display 1920×1080; PNGs verified 1920×1080 |
| A1 City 8 PNGs | **PASS** | All present; landmarks PlayerSpawn / CafeEntrance / HomeEntrance found |
| A2 Apartment 7 PNGs | **PASS** | All present; PlayerSpawn / BedAnchor / WindowAnchor / ApartmentExit / DiningTable found |
| A3 Cafe (`restaurant.tscn`) 7 PNGs | **PASS** | All present; PlayerSpawn / RestaurantExit / Counter / DateFocus / TableWestFront found |
| Filenames exact | **PASS** | Exact basename list matched |
| Non-trivial PNG sizes | **PASS** | Smallest ~381 KB (`legacy_cafe_03_counter`); city_03 fixed after black-frame retry |
| Visual content matches filename intent | **PASS** with notes | Spot-checked images; see camera notes / warnings |
| No Stage B started | **PASS** | Not begun |

---

## Summary

Independent Stage A capture was executed in a disposable Godot 4.7 project that mirrors only the needed donor scenes/assets. A capture runner loaded `city.tscn`, `apartment.tscn`, and `restaurant.tscn`, placed a `Camera3D` from landmark markers (with street-axis approximations for city overview axes), waited for frames, and saved PNGs to `tmp/visual_bootstrap_review/legacy/`.

One city shot (`legacy_city_03_main_street_left`) initially faced void/fill geometry and was nearly black; camera was repositioned along the cafe-side sidewalk and re-captured successfully.

---

## Changed files (tmp only)

Writable scope only:

- `tmp/vb_legacy_capture_proj/**` — disposable mirror + runner + stubs + logs
- `tmp/visual_bootstrap_review/legacy/*.png` — 22 required captures
- `docs/agent/qa/VISUAL_BOOTSTRAP_STAGE_A_QA.md` — this report

Not changed: `date_factory_legacy/**`, live world/locations gameplay scenes.

---

## PNG inventory (sizes)

| File | Bytes |
|---|---:|
| legacy_city_01_spawn_forward.png | ~1,205,244 |
| legacy_city_02_spawn_back.png | ~673,209 |
| legacy_city_03_main_street_left.png | ~1,527,473 |
| legacy_city_04_main_street_right.png | ~691,819 |
| legacy_city_05_cafe_approach.png | ~1,610,969 |
| legacy_city_06_intersection.png | ~392,564 |
| legacy_city_07_long_view_a.png | ~957,098 |
| legacy_city_08_long_view_b.png | ~1,238,345 |
| legacy_room_01_spawn.png | ~605,535 |
| legacy_room_02_bed.png | ~722,263 |
| legacy_room_03_window.png | ~626,504 |
| legacy_room_04_main_area.png | ~702,429 |
| legacy_room_05_door.png | ~464,421 |
| legacy_room_06_wide_a.png | ~793,428 |
| legacy_room_07_wide_b.png | ~608,060 |
| legacy_cafe_01_entrance.png | ~696,045 |
| legacy_cafe_02_center.png | ~429,103 |
| legacy_cafe_03_counter.png | ~381,102 |
| legacy_cafe_04_tables.png | ~392,518 |
| legacy_cafe_05_date_view.png | ~408,889 |
| legacy_cafe_06_reverse.png | ~664,689 |
| legacy_cafe_07_wide.png | ~566,390 |

Exact sizes also listed in `tmp/vb_legacy_capture_proj/png_sizes.txt` after final run.

---

## Camera / landmark notes

### City (`city.tscn`)

| Landmark | Result | Position |
|---|---|---|
| PlayerSpawn | found | (29.2, 0, 9) |
| CafeEntrance | found | (24.85, 0, 14.2) |
| HomeEntrance | found | (31.55, 0, 16.5) |

- Street treated as X-corridor with cafe/south facades ~z14 and north shops ~z5.3.
- `01` spawn forward toward street mid; `02` spawn back toward HomeEntrance.
- `03` cafe-side sidewalk looking west toward leisure; `04` looking east toward home block.
- `05` CafeEntrance approach; `06` approximate intersection near (8,10) looking to cafe.
- `07`/`08` elevated long views (approximate street axes; not named Marker3Ds).

### Apartment (`apartment.tscn`)

| Landmark | Result |
|---|---|
| PlayerSpawn | found |
| BedAnchor | found (Bed mesh also present) |
| WindowAnchor | found |
| ApartmentExit | found (ExitDoor mesh also present) |
| DiningTable | found → main area |

### Cafe (`restaurant.tscn`)

| Landmark | Result |
|---|---|
| PlayerSpawn | found |
| RestaurantExit | found → entrance framing |
| Counter/CounterMiddle | found |
| DateFocus | found |
| TableWestFront | found → tables |

Optional `legacy_street_*` from `street.tscn` was **not** captured (time/scope; not required).

---

## Missing meshes / materials observed

Non-blocking visual notes from opened PNGs:

1. **City night void sky** — pure black skybox; expected for donor night setup.
2. **City placeholder / CSG blocks** — featureless gray/black/orange blocks appear in some city frames (esp. cafe approach / street fills). Likely donor CSG void-fill or unfinished POI shells, not capture failure.
3. **Cafe neon / awning slab** — strong pink emissive rectangular volume at cafe exterior (reads as simplified sign/awning).
4. **City LotBounds / debug volumes** — capture runner hides `LotBounds` / `ExitTo*` where possible; earlier long-view showed translucent blue helpers before hide pass.
5. **Temp-project script stubs** — `Interactable` / `Sfx` / `InteractionRouter` class_name stubs did not fully register on first play sessions → SCRIPT ERROR parse noise in engine log. Geometry still loaded; POI interaction scripts not required for overview visuals.
6. **Cafe DateGirl** — character may be incomplete if anim class deps fail; environment/date table props (dango, chairs, counter) render correctly in cafe PNGs.
7. **Apartment** — furniture/materials load; simple flat materials (donor stylized low-poly), no magenta missing-texture fields observed in reviewed room shots.

---

## Blocking issues

None for Stage A acceptance (required PNG set complete and visually usable as donor overview reference).

## Non-blocking issues

1. Engine SCRIPT ERRORs in temp project for `Interactable` / `CityPOITenant` (missing class_name registration of stubs). Does not block PNGs.
2. City lighting is very dark; some frames are high-contrast night with large black regions (still show architecture).
3. Optional street reference shots not produced.
4. Exit-time RID leak warnings from Godot when quitting after scene swaps (engine noise).

---

## Evidence

- PNGs: `tmp/visual_bootstrap_review/legacy/legacy_*.png` (22 files)
- Capture notes: `tmp/vb_legacy_capture_proj/vb_capture_notes.txt`
- Engine logs:
  - `tmp/vb_legacy_capture_proj/godot_engine.log` (import)
  - `tmp/vb_legacy_capture_proj/godot_capture_run.log` (first capture)
  - `tmp/vb_legacy_capture_proj/godot_capture_run2.log`
  - `tmp/vb_legacy_capture_proj/godot_capture_run3.log` (final)
- Capture journal: lines prefixed `[VB_CAPTURE]` in those logs / `vb_capture.log`

## Reproduction steps

```powershell
$godot = "C:\godot\Godot_v4.7.1-stable_win64.exe"
$proj  = "c:\Users\User\Documents\GodotProjects\date_factory\tmp\vb_legacy_capture_proj"

# (Already done) robocopy donor scenes/assets into $proj; project.godot set to 1920x1080 + vb_capture_runner.tscn
& $godot --headless --path $proj --import
& $godot --path $proj --resolution 1920x1080

# Verify
Get-ChildItem "c:\Users\User\Documents\GodotProjects\date_factory\tmp\visual_bootstrap_review\legacy\*.png"
```

## Recommendation

**PASS** Stage A. Safe to proceed to Stage B when orchestrator starts it. Do not treat temp-project script parse noise as a live-game defect.
