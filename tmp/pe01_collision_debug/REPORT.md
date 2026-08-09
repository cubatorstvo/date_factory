# PE01 Apartment Collision Debug Evidence

**Task:** PLAYER EXPERIENCE PASS 01 — development-only apartment collision-debug artifacts  
**Role:** df-scene-worker  
**Date:** 2026-08-09  
**Branch (read-only):** `visual-review/player-experience-01-20260809` (source commit `a92f148`)  
**Writable scope used:** `tmp/pe01_collision_debug/**` only  
**Production mutation:** none (no Story/GameState/player-data calls; isolated `XDG_DATA_HOME`)

## Verdict

**PASS**

All six required PNGs were generated, opened, and verified to show production apartment visual meshes plus translucent overlays derived from live `StaticBody3D` / `CollisionShape3D` (and Architecture `CSGBox3D` `use_collision`) data. The final fitted `WardrobeBody` and `ExitDoorBody` boxes are inside their meshes' AABBs with zero room-face overhang.

## Helper (dev-only)

| Path | Role |
|---|---|
| `tmp/pe01_collision_debug/apartment_collision_debug_capture.tscn` | Capture main scene |
| `tmp/pe01_collision_debug/apartment_collision_debug_capture.gd` | Instances production `world/locations/apartment/apartment.tscn`, builds transparent box overlays, captures six views |
| `tmp/pe01_collision_debug/run_capture.ps1` | Launch wrapper |

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tmp/pe01_collision_debug/run_capture.ps1
```

Godot: `C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe`  
Args: `--path <project> --resolution 1280x720 --windowed --quit-after 90 res://tmp/pe01_collision_debug/apartment_collision_debug_capture.tscn`

Overlay method: read-only walk of production shapes → temporary `MeshInstance3D` boxes under `DevCollisionOverlay` (not written into production scenes). Color focus per shot. Architecture CSG collision shown faintly amber.

Overlay count this run: **18** (13 furniture/door `Colliders/*` StaticBodies + 5 Architecture CSG `use_collision` boxes). Disabled Geometry blockout shapes skipped.

## Evidence PNGs (opened)

Exact paths under `tmp/pe01_collision_debug/evidence/`:

| File | What the opened image shows |
|---|---|
| `apartment_collision_overview.png` | High room view: kitchen (orange), bed/nightstand (cyan), dining table+chairs (green), storage/wardrobe (magenta), exit slab (pink/red), floor/walls context |
| `apartment_collision_bed.png` | Bed + nightstand (+ lamp) meshes with cyan `BedBody` / `NightStandBody` boxes highlighted |
| `apartment_collision_table.png` | Round dining table + two chairs with green `DiningTableBody` / chair boxes |
| `apartment_collision_kitchen.png` | Fridge + counter run (drawers/sink/oven) with orange kitchen `StaticBody` boxes |
| `apartment_collision_storage.png` | Dresser/wardrobe mesh with its magenta `WardrobeBody` fitted to the visible height and width |
| `apartment_collision_exit.png` | City exit door mesh with its pink/red `ExitDoorBody` inset onto the visible door leaf |

Final mesh-AABB fit:

| Collider | Final box size / origin | Mesh AABB size / center |
|---|---|---|
| `WardrobeBody` | `(0.56, 1.05, 1.42)` @ `(2.152, 0.53, 0.95)` | `(0.582, 1.076, 1.453)` @ `(2.152, 0.534, 0.95)` |
| `ExitDoorBody` | `(0.18, 2.06, 0.84)` @ `(-2.43, 1.03, 0.684)` | `(0.208, 2.094, 0.868)` @ `(-2.42, 1.047, 0.684)` |

## Raw Godot engine log

Canonical copy: `tmp/pe01_collision_debug/godot_engine.log`  
Timestamped: `tmp/pe01_collision_debug/logs/godot_collision_debug_20260809_231546.log`

Key lines:

- Engine: Godot 4.7.1 stable / Vulkan Forward+ / RTX 4060 Laptop  
- Autoloads ready; boot banner printed (main scene was the capture scene — no title-menu boot)  
- `PE01_COL_DBG: overlay_count=18`  
- Six `CAPTURE ... err=0` lines with absolute PNG paths  
- `PE01_COL_DBG: ALL PASS (9)`  
- Exit-time RID/resource leak errors/warnings (same class as other PE01 windowed captures; process exit code 0)

## Limitations

1. Diagnostics only — overlays are helper geometry, not player-facing UI.  
2. Overlay geometry uses `no_depth_test`; it can look slightly in front of a mesh even when the collider is inset. The AABB fit above is authoritative.  
3. Architecture CSG wall/floor collision is visualized faintly; disabled Geometry blockout colliders are not.  
4. GodotIQ MCP unavailable; native Godot CLI used.  
5. Exit RID leak spam is engine teardown noise from this capture pattern, not a gameplay failure.

## Unmet criteria

None for the requested artifact set.

## Recommendation

**PASS** — deliver evidence bundle as PE01 collision-debug QA artifacts.
