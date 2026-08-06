# APT-INTERACT-COMPONENT-001 — Independent QA

**Task ID:** APT-INTERACT-COMPONENT-001-QA  
**Date:** 2026-08-05  
**QA agent:** df-qa-worker (independent; did not trust implementation report)  
**Scope written:** this file only  
**Overall status:** **PASS**  
**Recommendation to Orchestrator:** **READY**

---

## Summary

Normal boot → Continue → apartment FPS. Fridge and KitchenDrawers Interactables are child components under their furniture hosts, collision boxes fit mesh AABB + padding, and world AABBs do **not** intersect (X gap ≈ **0.0107**). Focus fridge → food-only ShopUI; focus drawers → drink-only ShopUI; 8-step aim alternation had no dual-focus and no wrong hits. Outline materials bind the correct furniture meshes. Bed / DiningTable / ExitDoor remain aimable and parented correctly. Debugger: 0 script/runtime errors. Viewport screenshots timed out in this session (non-blocking); outline verified via runtime shader params.

---

## Criterion-by-criterion

### 1. Project parse clean
| Status | **PASS** |
|---|---|
| Evidence | `godotiq_check_errors(scope=project)` → `errors=[]`, `scripts_checked=95`, `total=0`. |
| Reproduction | Open project; run project-wide GDScript check. |

### 2. Normal launch → apartment FPS
| Status | **PASS** |
|---|---|
| Evidence | `godotiq_run(play, scene=main)` → Boot. Tap **Продолжить** → `Main` (`res://scenes/boot/main.tscn`), player present at `(-1.55, 0.0, 0.25)`, HUD crosshair + resources visible (`loc` home via ComplexWorld). |
| Reproduction | Launch main → Continue → spawn in apartment FPS. |

### 3. Fridge Interactable under Fridge; Drawers under KitchenDrawers
| Status | **PASS** |
|---|---|
| Evidence | Runtime tree: Fridge children include `@Area3D@22` (Interactable); KitchenDrawers children include `@Area3D@24`. `parent_is_host=true` for both. Paths: `.../Furniture/Fridge/@Area3D@22`, `.../Furniture/KitchenDrawers/@Area3D@24`. |
| Reproduction | In apartment, inspect Furniture/Fridge and Furniture/KitchenDrawers children. |

### 4. World AABBs fridge vs drawers — no intersection; sizes/gap
| Status | **PASS** |
|---|---|
| Evidence | Via `get_collision_world_aabb()`: |

| | Fridge | KitchenDrawers |
|---|---|---|
| **pos** | `(-2.4413, -0.0259, -2.5039)` | `(-1.6480, -0.0300, -2.4480)` |
| **size** | `(0.7826, 1.9789, 0.7851)` | `(0.5961, 0.9697, 0.6574)` |
| **end** | `(-1.6587, 1.9530, -1.7188)` | `(-1.0520, 0.9397, -1.7906)` |
| **center** | `(-2.0500, 0.9636, -2.1114)` | `(-1.3500, 0.4549, -2.1193)` |

| | Value |
|---|---|
| **intersects** | `false` |
| **gap_x (fridge.end.x → drawers.pos.x)** | **0.0107** |
| **sep** | `{dx: 0.0107, dy: 0.0, dz: 0.0}` |

Mesh AABB vs collision (fit + padding `(0.015, 0.03, 0.015)` ×2): Fridge mesh size `(0.7526, 1.9189, 0.7551)` → col `(0.7826, 1.9789, 0.7851)`; Drawers mesh `(0.5661, 0.9097, 0.6274)` → col `(0.5961, 0.9697, 0.6574)`.

| Reproduction | Call `get_collision_world_aabb()` on both Areas; compare `AABB.intersects`. |

### 5. Focus fridge → food-only; drawers → drink-only; no cross-flicker
| Status | **PASS** |
|---|---|
| Evidence | Ray aim fridge center → collider = fridge Area, prompt `Холодильник [Выбрать еду]`, drawers `_focused=false`. Aim drawers → prompt `Кухонные ящики [Выбрать напиток]`, fridge unfocused. Flicker seq (8 alternations): hits `fridge/drawers/...` only; `any_dual_focus=false`, `any_wrong_hit=false`. Interact fridge → ShopUI `_kind=home_food`, `_items=[simple_meal, snack_plate, nice_meal, dessert]`, title **Холодильник**. Interact drawers → `_kind=home_drink`, `_items=[water, juice, wine]`, title **Кухонные ящики**. No drink IDs in food list; no food IDs in drink list. |
| Reproduction | Stand in kitchen; aim fridge vs drawers; E to open menus; alternate aim rapidly. |

### 6. Outline on correct furniture meshes
| Status | **PASS** (runtime) / **WARNING** (no viewport image this session) |
|---|---|
| Evidence | Fridge `_external_outline_roots` → `Furniture/Fridge`, meshes `Kitchen_Fridge`, `Kitchen_Fridge2`, `_outline_mats=2`. Drawers → `Furniture/KitchenDrawers`, meshes `Kitchen_2Drawers`, `Kitchen_2Drawers2`. Bed control: `Bed_Single`/`Bed_Single2`. On focus: fridge `outline_width=3.0`, drawers unfocused `0.0`; swap reverses. Pink idle color `(1.0, 0.35, 0.58, …)` matches prior kitchen QA style. **Screenshot:** `godotiq_screenshot` / `explore` timed out after 30s (tool failure); visual pixels not captured. |
| Reproduction | Focus fridge/drawers; confirm pink SS outline on that unit only. |

### 7. Bed / table / exit still interactable
| Status | **PASS** |
|---|---|
| Evidence | All parented under furniture hosts with collision: Bed `job` / `Кровать / Работа [Поработать]`; DiningTable `prepare_and_start` / `Кухонный стол [Положить / сесть / начать]`; ExitDoor `go_outside` / `На улицу [Выйти в город]`. Ray aim each AABB center → hit correct Area, `_focused=true`. |
| Reproduction | Aim bed, table, exit door from apartment; confirm prompts. |

### 8. Optional city interact smoke
| Status | **WARNING** |
|---|---|
| Evidence | Optional. Direct `ExitDoor.on_interact` while overlays/`_traveling` could stick did not leave home. Clearing `_traveling` and `travel_to(&"city")` started travel (`traveling=true`) but location still reported `home` before transition completed; subsequent city scans timed out. Not exercised cleanly without long wait. Apartment criteria unaffected. |
| Reproduction | Clear UI overlays → exit door → wait for city → aim one street interact. |

### 9. Debugger: no script/runtime errors
| Status | **PASS** |
|---|---|
| Evidence | `godotiq_read_debug_console`: `runtime_errors_total=0`, `script_errors_total=0`, `entries=[]` during apartment probes. `_editor_state.recent_errors=[]`. |
| Reproduction | Play apartment kitchen flow; read Debugger. |

### 10. Restore / stop cleanly
| Status | **PASS** |
|---|---|
| Evidence | Unlocked `_traveling` / `_date_lock` after probes; `godotiq_run(action=stop)` succeeded. Editor returned to non-running state for report write. |
| Reproduction | Stop Play from editor / GodotIQ stop. |

---

## Edge cases checked

1. **Rapid aim fridge ↔ drawers (8×):** no dual focus, no wrong collider — PASS.  
2. **Menu exclusivity:** food list has zero drinks; drink list has zero foods — PASS.  
3. **AABB clearance:** positive X gap 0.0107, `intersects=false` — PASS.

---

## Overall status

**PASS** → Orchestrator recommendation: **READY**

### Blocking issues
- None.

### Non-blocking issues
1. Viewport screenshot / explore capture timed out in this QA session — outline verified by runtime mats/roots/width only.  
2. Optional city interact smoke not completed (travel/transition stuck mid-probe).  
3. EventUI crisis popup was visible from save state when opening fridge (save content, not interact-component regression).

### Evidence
- GodotIQ: `project_summary`, `check_errors(project)`, `run(play)`, `input(Continue)`, multiple `exec` AABB/focus/shop probes, `ui_map`/`ShopUI` item lists, `read_debug_console`, `run(stop)`.  
- Exact AABB numbers in criterion 4.  
- No gameplay/code/scene/asset edits by QA.

### Reproduction steps
1. Play main scene → **Продолжить**.  
2. Walk to kitchen; aim Fridge → prompt food; E → food-only list; close.  
3. Aim KitchenDrawers → prompt drink; E → drink-only list; close.  
4. Aim rapidly between Fridge and Drawers — no dual outline/prompt flicker.  
5. Confirm bed, dining table, exit still show interact prompts.  
6. Stop Play.
