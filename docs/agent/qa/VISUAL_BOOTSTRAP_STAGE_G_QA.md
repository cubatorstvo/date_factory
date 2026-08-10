# VISUAL BOOTSTRAP STAGE G — Independent Technical QA

**Task ID:** VISUAL_BOOTSTRAP_STAGE_G  
**Agent:** df-qa-worker  
**Date:** 2026-08-09  
**Godot:** `C:\godot\Godot_v4.7.1-stable_win64.exe` (4.7.1-stable)  
**Project:** `c:\Users\User\Documents\GodotProjects\date_factory`

## Overall status

**PASS**

## Recommendation for Orchestrator

**READY** — technical verification of Stages A–F visual bootstrap routes, markers, donor isolation, DateVenue interactable presence, save/load smoke, and screenshot inventory. No critical route breakages found. No production code changes by QA.

---

## Per-check table

| # | Check | Status | Evidence | Reproduction |
|---|---|---|---|---|
| 1 | Load locations via World travel (apartment, city_hub, cafe, salary_mine, laboratory, production_area) | **PASS** | All `request_travel` rc=0; `current_location_id` matches. Unlock via `GameState.restore_stage` 1/3/5/6 (+ `mark_girl_conquered("scientist")` for lab). | Harness below |
| 2 | No donor runtime dependency in production paths | **PASS** | ripgrep `world/`,`assets/`,`characters/`,`data/` → 0 matches for `date_factory_legacy` / `../date_factory`. Runtime `scene_file_path` scan on loaded locs → 0. Static DirAccess text scan → 0. | Shell rg + harness static/runtime scans |
| 3 | Missing resources (critical Failed to load for location meshes) | **PASS** | Raw Godot stdout has no `Failed to load` / missing mesh errors during travel. Exit-time RID/ObjectDB leak noise only (known headless teardown). | `tmp/vb_stage_g_verify/godot_stdout.log` |
| 4 | Markers exist after travel | **PASS** | All required markers found with scripts/positions (see §Markers). | Harness marker probes |
| 5 | Early route apartment→city_hub→cafe→city_hub→apartment | **PASS** | Full chain at STAGE_1. | Harness early-route block |
| 6 | Cafe DateVenue interactable path | **PASS** | Present; script `res://game/dating/date_venue_interactable.gd`; `get_interaction_prompt` → `[E] Столик для свиданий`; `can_interact(null)=true`. **Method used:** node presence + script API (`get_interaction_prompt` / `can_interact`). No dating-schedule cheat invented. | Harness cafe DateVenue block |
| 7 | Visual presence (non-cube bootstrap) | **PASS** | apartment `Geometry/ApartmentArt` kids=6; city `Geometry/DonorCity`; cafe `Geometry/DonorCafe`; mine `Geometry/PackVisuals` kids=85; lab `Geometry/SciFiDressing` kids=61; production `Geometry/DressedShell` kids=160. Screenshots opened and match location names. | Harness + PNG open |
| 8 | Screenshot inventory vs TZ lists | **PASS** | legacy PNG=22/22; current PNG=43/43; no missing names; no extras. | Inventory § below |
| E1 | Edge: repeated cafe travel | **PASS** | Two consecutive `request_travel(cafe)` succeed. | Harness |
| E2 | Edge: STAGE_1 blocks production_area | **PASS** | `request_travel(production_area)` rc=1; location stays cafe. | Harness |
| SL | Save/load smoke | **PASS** | `SaveSystem.save_slot(MANUAL_1)` + travel city + `load_slot(MANUAL_1)` → `after_load_location=apartment`. Non-blocking World warning: saved player pose invalid → spawn_default. | Harness |

---

## Markers detail (post-travel)

| Location | Marker | Result |
|---|---|---|
| apartment | Phone, DayAdvance, DateVenue, ToCity, spawn_default | PASS |
| city_hub | ToCafe, ToApartment, spawn_default, DonorCity (`Geometry/DonorCity`) | PASS |
| cafe | DateVenue, ToCity, DonorCafe (`Geometry/DonorCafe`), spawn_default | PASS |
| salary_mine | SalaryStation, ToCity | PASS |
| laboratory | FirstCloneMachineInteractable, CloneTerminalInteractable, clone_date_slot_01, ToCity | PASS |
| production_area | GlobalExpansionTerminalInteractable, ToCity | PASS |

---

## Screenshot inventory

### Counts

| Folder | PNG count | Expected (TZ A–F) | Missing | Extra |
|---|---:|---:|---|---|
| `tmp/visual_bootstrap_review/legacy/` | 22 | 22 | none | none |
| `tmp/visual_bootstrap_review/current/` | 43 | 43 | none | none |
| **Total PNG** | **65** | **65** | — | — |

(Also present: matching `.png.import` sidecars; not counted as inventory shots.)

### Legacy list (22) — all present

`legacy_room_01`…`07`, `legacy_city_01`…`08`, `legacy_cafe_01`…`07`

### Current list (43) — all present

`current_room_01`…`07`, `current_city_01`…`08`, `current_cafe_01`…`07`, `current_mine_01`…`05`, `current_lab_01`…`06`, `current_late_01`…`05`, `current_chars_01`…`05`

### Opened PNG spot-check (filename ↔ content)

| File | Actual content |
|---|---|
| `legacy/legacy_room_01_spawn.png` | Apartment interior: bed, round date table, dresser — matches room spawn. |
| `current/current_room_01_spawn.png` | Apartment with DateVenue/Day labels (`Стол для свидания`, `ДЕНЬ`) — non-cube donor furniture. |
| `current/current_city_01_spawn_forward.png` | City street, brick building, NPC — DonorCity density; some white placeholder volumes remain. |
| `current/current_cafe_01_entrance.png` | Cafe interior tables/chairs/counter — DonorCafe landed; multiple NPC instances visible. |
| `current/current_mine_01_entrance.png` | Factory-style dressed interior (PackVisuals). |
| `current/current_lab_01_entrance.png` | Sci-fi lab with labels `ЛАБОРАТОРИЯ` / `ТЕРМИНАЛ` — SciFiDressing. |
| `current/current_late_01_entrance.png` | Production area with `ГЛОБАЛЬНЫЙ ТЕРМИНАЛ` — DressedShell. |
| `current/current_chars_01_male_base.png` | Male base mesh T-pose on neutral ground — character base usable. |

---

## Engine log paths (raw Godot stdout)

| Path | Role |
|---|---|
| `tmp/vb_stage_g_verify/godot_stdout.log` | **Raw Godot stdout/stderr** from Stage G harness (second run includes save/load). |
| `tmp/vb_stage_g_verify/stage_g_report.log` | Capture journal (PASS/FAIL lines from harness). |
| `tmp/vb_stage_g_verify/stage_g_journal.txt` | Duplicate journal write. |

Harness: `tmp/vb_stage_g_verify/stage_g_verify.gd`  
Command:

```text
C:\godot\Godot_v4.7.1-stable_win64.exe --path c:\Users\User\Documents\GodotProjects\date_factory --headless -s res://tmp/vb_stage_g_verify/stage_g_verify.gd
```

Result: `STAGE_G_OVERALL=PASS pass=50 fail=0 warn=0`

Unlock helpers used (existing patterns only):

- `GameState.reset_for_new_game`
- `GameState.restore_stage(1|3|5|6)`
- `GameState.mark_girl_conquered(&"scientist")` for laboratory
- `World.set_auto_reset_on_state_reset_for_test(false)` / `ensure_host` / `reset_to_start` / `request_travel`
- `SaveSystem.save_slot` / `load_slot` with `SaveTypes.Slot.MANUAL_1`

---

## Critical issues

None.

## Non-blocking limitations

1. **Headless exit leaks** — ObjectDB/RID/dependency warnings on quit after multi-travel (pre-existing engine teardown noise; not gameplay failure).
2. **World pose warning on load** — `[World] saved player pose invalid; keeping spawn_default` during save/load smoke; location still restored to apartment.
3. **City white volumes** — current city shots still show large untextured white blocks among donor buildings (visual polish; routes OK).
4. **Apartment residual white blocks** — some placeholder slabs remain near furniture in current room shots.
5. **Cafe NPC density** — review shot shows many duplicate character instances (including shirtless male base); presentation, not route break.
6. **DateVenue full dating session** — proven interactable API only; full schedule→date UI flow not forced (no invented dating cheats beyond established stage restore).

---

## Blocking issues

None.

## Reproduction steps

1. Ensure Godot 4.7.1 at `C:\godot\Godot_v4.7.1-stable_win64.exe`.
2. Run harness command above.
3. Confirm stdout ends with `STAGE_G_OVERALL=PASS`.
4. Confirm `tmp/vb_stage_g_verify/godot_stdout.log` has no `Failed to load` for location meshes.
5. Confirm PNG counts: legacy 22, current 43 under `tmp/visual_bootstrap_review/`.
6. Optionally open named PNGs and verify content matches filename prefixes (room/city/cafe/mine/lab/late/chars).

---

## Evidence summary

- Independent Godot headless run (not executor self-report alone).
- Travel + markers + visuals + donor isolation + DateVenue API + save/load + inventory.
- Screenshots opened and described for representative locations.
- QA did **not** redesign locations or change gamedesign; only wrote `tmp/vb_stage_g_verify/**` + this report.
