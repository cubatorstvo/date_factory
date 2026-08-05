# City Hub Expansion — Final Report (§34-style)

**Project:** DATE FACTORY  
**Date:** 2026-08-04  
**Scope:** Passes 1–5 (this session completed Pass 5 + report)

Honest status: **Pass 5 is implemented in code** with check_errors on edited scripts. Full FPS playthrough of every Pass 5 branch was **not** completed this session — classify as **editor-smoke + compile-clean**, not full playtest VERIFIED.

---

## Districts created

| District / cluster | Status | Notes |
|--------------------|--------|-------|
| `main_street` | **Playable** | Cafe, shops, home door (Pass 1) |
| `park_leisure` | **Playable** | Park gate, picnic, restaurant, leisure strip (Pass 2–3) |
| `agency_row` | **Playable** | Photo / barber / agency office (Pass 4) |
| Home cluster (vertical) | **Playable (scaffold art)** | Main apt + lab + optional themed apts via elevator (Pass 5) — not a city district flag |

---

## Activities that work

| Activity | Status |
|----------|--------|
| Cafe sit-wait date | **Playable** |
| Shops (flower/jewelry/gift/clothing/homeware) | **Playable** |
| Park picnic + rain handoff | **Playable** |
| Restaurant sit-wait | **Playable** |
| Gym session UI | **Playable** |
| Bookstore browse/shop | **Playable** |
| Cinema date beats | **Playable** |
| Photo studio shoot + publish | **Playable** |
| Barber style tags + toast | **Playable** (mesh not updated) |
| Agency schedule board | **Playable** |
| Lab create_clone / acceptance | **Playable** (needs scientist / unlock_clones) |
| Elevator travel home zones | **Playable** |
| Buy / travel themed apartments | **Playable** (greybox) |
| Themed apt as date place (phone) | **Playable** when unlocked |
| Capacity conflict toast + board flag | **Playable** (logic) |
| Elevator wrong-girl incident | **Playable** (chance when clone auto active) |

---

## Minigames implemented

| Minigame | Pass | Status |
|----------|------|--------|
| Pair Overload (arcade) | 3 | **Playable** |
| Gym timing presses | 3 | **Playable** (activity, not full minigame) |
| Photo pose + SubViewport capture | 4 | **Playable** |
| Elevator incident choice | 5 | **Playable** (binary choice UI, not a skill game) |

No new skill-minigame in Pass 5 beyond the elevator incident prompt.

---

## Apartments available

| Id | How unlocked | Visual | Bookable |
|----|--------------|--------|----------|
| Main `apartment` | Start | Art-backed vertical slice | Yes (`home`) |
| `apt_cozy` | First clone **or** stage_4 + 200$ | Greybox warm props | Yes |
| `apt_modern` | First clone **or** stage_4 + 350$ | Greybox cool/minimal | Yes |
| `apt_creative` | First clone **or** stage_4 + 280$ | Greybox accent panels | Yes |
| Neighbor apt | Start | Greybox | Visit only (not date place) |

Unlock / buy: Elevator UI or Agency board. Travel: elevator (direct entry, no shared corridor).

---

## Elevator incidents that work

| Incident | Trigger | Choices | Effects |
|----------|---------|---------|---------|
| Wrong girl waiting | `has_active_clone_date()` and ~45% roll on destination select | «Подождать следующий» (safe) / «Ехать вместе» (risk) | Wait: toast only. Ride: scandal + legend damage + bond −4 on booked girl if any |

**Limits:** chance-based only; no persistent “wrong girl waiting” world flag; no visual NPC in the elevator cabin.

---

## District gating (redesign)

| Item | Status |
|------|--------|
| Gym / bookstore / cinema / arcade on main_street | **Fixed** — street-side gym interact removed from `city_builder`; leisure POIs stay west of `ParkGate` |
| GTA/NFS gate UX | **Shipped** — semi-transparent barrier + `inspect_district_gate` → `DistrictGateUI` (requirements + contents) |
| `park_leisure` unlock copy | stage_2 **or** venue `park` |
| `agency_row` unlock copy | stage_3 **or** room `agency` |
| Agency gate reachable before park | Still only after park opens (wall order) — expected |

## Remaining limits

1. Still **one player booking** at a time; capacity conflicts mainly vs clone/manager **live autos** (`minutes=-1`) and duplicate slot keys on the board.  
2. Themed apartments are **greybox**, not unique art scenes.  
3. Lab reuses `Clone_Lab_Base` when mount succeeds; interact volumes are procedural.  
4. Barber does not change Hero mesh.  
5. Agency assignment is a simple apt→girl/lead dict (no full calendar UI).  
6. Elevator incident is minimal sim — not a full scandal setpiece.  
7. District gate UI is editor-smoke / compile-clean; full FPS walk to both gates not re-playtested this pass.

---

## Playtested vs editor-smoke

| Scenario | Evidence this session |
|----------|----------------------|
| Pass 1–4 routes | Prior sessions / docs claim IN CODE; not re-playtested here |
| Pass 5 script compile (`check_errors`) | **Done** on edited scripts (date_schedule, dating_api, city_api, complex_world, elevator_ui, phone_ui, agency_board, interaction_router, …) |
| Lab basement → create_clone in running game | **Editor-smoke only** (not runtime-attached FPS walk) |
| Elevator buy/travel themed apt | **Editor-smoke only** |
| Occupancy conflict toast with live clone auto | **Logic shipped; not live-playtested** |
| Wrong-girl elevator choices | **Logic + UI shipped; not live-playtested** |
| Agency board assign/buy | **UI shipped; not live-playtested** |

**Verdict:** Pass 5 is **partially playable in code** (scaffold architecture complete). Do **not** mark full Pass 5 as playtest-VERIFIED until a runtime walk of lab → clone → buy apt → elevator incident → conflict toast is done.

---

## Key files (Pass 5)

- `modules/dating/date_schedule.gd` — occupancy
- `modules/dating/dating_api.gd` — auto occupancy / `has_active_clone_date`
- `modules/dating/date_places.gd` — themed places
- `modules/city/city_api.gd` — apt unlock / elevator / board
- `scenes/world/complex_world.gd` — lab / themed rooms / travel zones
- `scenes/ui/elevator_ui.gd` — elevator + incident
- `scenes/ui/agency_board_ui.gd` — assign/buy
- `scenes/ui/phone_ui.gd` — themed book button
- `modules/interaction/interaction_router.gd` — elevator/lab routes
- `docs/DATING_AND_WORLD.md`, `docs/IMPLEMENTATION_STATE.md`
