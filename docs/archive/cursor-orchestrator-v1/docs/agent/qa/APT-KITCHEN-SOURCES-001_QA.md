# APT-KITCHEN-SOURCES-001 — Independent QA

**Task ID:** APT-KITCHEN-SOURCES-001-QA  
**Date:** 2026-08-04  
**QA agent:** df-qa-worker (independent; did not trust implementation report)  
**Scope written:** this file only  
**Overall status:** **PASS**  
**Recommendation to Orchestrator:** **READY**

---

## Summary

Normal boot → Continue → apartment FPS. Fridge opens food-only ShopUI; KitchenDrawers opens drink-only ShopUI. Old separate food/drink interactables are gone. Fridge/Drawers share the same pink screen-space outline style as other interactables (e.g. bed). Oven/Drawers swap is clean: Fridge → Drawers → Sink → Oven, no overlap, passage in front usable. No parser/script errors; no missing-resource errors on the kitchen path.

---

## Criterion-by-criterion

### 1. Normal project launch → apartment FPS
| Status | **PASS** |
|---|---|
| Evidence | `godotiq_run(play, scene=main)` → Boot menu. Tap **Продолжить** → `Main`, `loc=home`, HUD crosshair + resources, FPS apartment view. |
| Reproduction | Launch project main scene → Continue → spawn in apartment. |

### 2. Fridge focus outline (same 2D style as other interactables)
| Status | **PASS** |
|---|---|
| Evidence | Focused fridge `_outline_mats` count=2, `outline_width=3.0`, color `(1.0, 0.35, 0.58, 1.0)`. Bed same width `3.0`. Explore/inspect screenshots show bright pink screen-space silhouette on Fridge and KitchenDrawers. Drink-menu gameplay screenshot also shows pink outline on the focused kitchen unit behind the panel. |
| Reproduction | Stand facing kitchen → focus Fridge/Drawers → pink SS outline matches bed/table interactables. |

### 3. Fridge interact → food-only menu → select one food
| Status | **PASS** |
|---|---|
| Evidence | Interactable: `Холодильник | Выбрать еду | take_food | {}`. ShopUI: title **Холодильник**, kind `home_food`, button **Взять**, subtitle **Выбери и возьми в руки**. List only food: `simple_meal`, `snack_plate`, `nice_meal`, `dessert` (no drinks). After **Взять**: `carried=food:simple_meal`. Screenshot of food menu captured and opened. |
| Reproduction | Interact Fridge → food list → Взять. |

### 4. Close / reopen Fridge → mouse / control recovery
| Status | **PASS** |
|---|---|
| Evidence | Reopen after take succeeded (`kind=home_food` again). Clean `open_home_prep("food")` → `close()` with no other overlays: `shop_vis=false`, `mouse_after_close=2` (`MOUSE_MODE_CAPTURED`). Earlier sticky mouse (`mouse=0`) was when EventUI from save was still considered open — not kitchen-menu logic itself. |
| Reproduction | Open fridge menu → Закрыть (with no event/phone overlay) → mouse recaptured for FPS. |

### 5. KitchenDrawers identical outline style
| Status | **PASS** |
|---|---|
| Evidence | Drawers focused: `_outline_mats=2`, `outline_width=3.0`, color `(1.0, 0.35, 0.58, 1.0)` — identical to Fridge. Bound via `_bind_interact_outline(..., "Furniture/KitchenDrawers")`. |
| Reproduction | Focus Drawers after Fridge; outline params/visual match. |

### 6. KitchenDrawers interact → drink-only menu → select one drink
| Status | **PASS** |
|---|---|
| Evidence | Interactable: `Кухонные ящики | Выбрать напиток | take_drink | {}`. ShopUI: title **Кухонные ящики**, kind `home_drink`, list only drinks: water / juice / wine. With empty carry, `take_drink` → `carried=drink:water`. Screenshot of drink menu captured and opened (pink outline visible behind panel). |
| Reproduction | Interact KitchenDrawers → drink list → Взять. |

### 7. Close / reopen Drawers
| Status | **PASS** |
|---|---|
| Evidence | Reopen drink menu after food cycle; close restores capture when overlays clear (see #4). |
| Reproduction | Open drawers → close → reopen → close. |

### 8. Old separate food/drink prompts absent
| Status | **PASS** |
|---|---|
| Evidence | Live Area3D scan: `old=[]` for names Вода/Сок/Вино/Закуски/Десерт. Only home food/drink sources: Fridge `take_food {}` and Drawers `take_drink {}` (+ separate Посуда homeware). Diff removes prior per-item `_add_interact` points. HUD never showed old prompts during walk/kitchen focus (saw Посуда / kitchen menus only). |
| Reproduction | Walk apartment kitchen; scan interactables — no legacy prompts. |

### 9. Oven / Drawers swapped cleanly; 5×5 passage usable
| Status | **PASS** |
|---|---|
| Evidence | Runtime globals: Fridge `(-2.05,0,-2.15)`, Drawers `(-1.35,0,-2.15)`, Oven `(0.05,0,-2.15)`. Distances: Fridge–Drawers `0.70`, Drawers–Oven `1.40`, `overlap=false`. Physics ray across front of kitchen: no hit. Scene map order west→east: Fridge, Drawers, Sink, Oven. Explore screenshots: kitchen row with open floor in front; no furniture interpenetration. |
| Reproduction | Face kitchen wall; confirm Drawers left of Sink/Oven (Oven right), walk along counter. |

### 10. Debugger / stdout — parser, runtime, missing resources
| Status | **PASS** |
|---|---|
| Evidence | `godotiq_check_errors(scope=project)`: 0 errors / 95 scripts. During kitchen tests: no missing-resource / parser failures. One NavigationServer map-sync error appeared only after QA `nav_query` (apartment navmesh not ready) — tool-induced, not kitchen feature. |
| Reproduction | Play normal route; read debug console. |

---

## Edge cases

| Case | Status | Evidence |
|---|---|---|
| Repeat both menu opens | **PASS** | Fridge reopen after take; drawers open after fridge cycle. |
| Menu close restores FPS mouse capture | **PASS** | Clean close → `mouse_mode=2`. Sticky mouse only with other overlay open. |
| Empty / unavailable catalog | **WARNING** | Live catalogs non-empty (`food=4`, `drink=3`). Invalid kind `open_home_prep("not_a_kind")` does not open UI (`invalid_open_vis=false`). Empty-list toast path exists in code but was not runtime-forced (would require mutating catalog/save — avoided). |
| Re-enter / rebuild apartment; old interactions do not respawn | **WARNING** | In-session home rebuild via `travel_to(city/home)` timed out / stopped session. While in home, sources remained Fridge+Drawers only and `old=[]`. Code path in `complex_world.gd` no longer spawns legacy points. Full leave/re-enter not completed in this QA run. |

---

## Normal route verified

1. Main/boot launch (not a debug-only scene).  
2. **Продолжить** into saved game.  
3. Apartment FPS (`loc=home`).  
4. Kitchen food/drink menus exercised.  
5. Game stopped cleanly after checks.

Note: An EventUI consequence popup appeared from save state on Continue; dismissed with **Игнорировать** before kitchen tests. Not part of kitchen change, but blocked input until dismissed.

---

## Engine logs

| Check | Result |
|---|---|
| Project parse (`check_errors` project) | 0 errors |
| Startup / kitchen play debug console | Clean during primary route |
| Post-QA `nav_query` | NavigationServer map sync error (QA tool; ignore for feature) |
| Missing resources on fridge/drawers/shop | None observed |

---

## Screenshots opened / described

| Shot | What it actually shows |
|---|---|
| Boot menu | DATE FACTORY title; buttons Новая игра / Продолжить / Настройки / Выход. |
| Early apartment + EventUI | Kitchen wall with white fridge + dark drawers/oven behind Russian event popup about дубль hair mismatch. |
| Fridge food menu | Panel **Холодильник**; “Выбери и возьми в руки”; four food lines only; **Взять** / **Закрыть**. |
| Drawers drink menu | Panel **Кухонные ящики**; three drink lines only; pink SS outline on kitchen unit behind menu; **Взять** / **Закрыть**. |
| Explore kitchen #1–#2 | Row Fridge → Drawers → Sink → Oven; pink outlines on fridge/drawers; open brown floor in front; no overlap. |

Independent captures via GodotIQ (not implementation-worker evidence).

---

## Blocking issues

None.

---

## Non-blocking issues

1. **WARNING — Re-enter travel incomplete:** `travel_to` city↔home timed out in QA; recommend one manual leave/re-enter smoke if desired. Wiring evidence still supports no legacy respawn.  
2. **WARNING — Empty catalog not forced:** current food/drink catalogs are non-empty; empty toast path not live-exercised.  
3. **Note — EventUI on Continue:** save-state consequence popup can interrupt kitchen testing until dismissed (pre-existing save content, not introduced by kitchen menus).  
4. **Note — Carry conflict:** taking a drink while already carrying food left carry as food until cleared; expected inventory replace rules, not a sources wiring defect.

---

## Reproduction steps (full acceptance)

1. Run project main scene.  
2. Continue (or New Game) into apartment FPS.  
3. Dismiss any EventUI if present.  
4. Face Fridge → confirm pink outline → E/interact → food-only list → Взять one food → Закрыть → confirm mouse capture.  
5. Face KitchenDrawers → same outline style → drink-only list → Взять one drink → close.  
6. Walk apartment: no Вода/Сок/Вино/Закуски/Десерт / direct simple-meal prompts.  
7. Confirm kitchen order Fridge–Drawers–Sink–Oven; walk past without collision into furniture.  
8. Optionally leave to city and return; confirm only Fridge/Drawers food/drink sources remain.  
9. Check Godot debugger for script/missing-resource errors.

---

## Recommendation

**READY** — Kitchen food/drink source consolidation meets acceptance on the normal route with independent runtime and visual evidence. Non-blocking warnings do not break the critical player path.
