# Dating & World — текущее состояние кода

**Обновлено:** 2026-08-04  
Отражает реализацию после плейтест-переработки свиданий + **City Hub Expansion Pass 1–5**. Цель дизайна по-прежнему в [04_SYSTEMS.md](04_SYSTEMS.md) / [08_FPS_AND_CRISES.md](08_FPS_AND_CRISES.md); здесь — **что уже в коде**.

---

## Игровые часы

| Элемент | Путь / API |
|---------|------------|
| Часы | `modules/time/time_api.gd` (`TimeAPI`), создаётся через `Game.time` |
| Тик | ~0.5 игровой минуты / реал-сек при `Game.run_started`, пауза во время активного свидания |
| HUD | `scenes/ui/hud.gd` — день/часы + строка расписания + wait-UI за столом |
| Слоты брони | `TimeAPI.next_slots()` (шаг 30 мин, lead ≥45 мин) |
| Gym / photo skip | `TimeAPI.advance_minutes()` из gym / photo studio |

---

## Расписание и места

| Элемент | Путь / API |
|---------|------------|
| Каталог мест | `date_places.gd` — home / cafe / park / restaurant / cinema / arcade + `apt_cozy` / `apt_modern` / `apt_creative` |
| Бронь | `date_schedule.gd` — `is_no_prep()` = cafe\|park\|restaurant\|cinema\|arcade; home-like = home + `apt_*` |
| Occupancy | `DateSchedule.place_occupancy` — shared places home/cafe/park/restaurant/`apt_*`; toast при конфликте слота |
| Unlock leisure | `DatePlaces.is_leisure_unlocked()` / cinema / arcade — **behind `ParkGate`**, not on main_street |
| Unlock agency | `DatePlaces.is_agency_row_unlocked()` — stage_3 **или** room `agency` — behind `AgencyGate` |
| District gates UX | `CityDistricts.info()` + `DistrictGateUI` (`inspect_district_gate`) — semi-transparent barrier, unlock copy + contents list |
| Gym / Pass 3 POIs | Leisure strip west of ParkGate (`Markers/GymEntrance` etc.); **removed** street-side gym from `city_builder` |
| Unlock themed apt | `CityAPI.buy_themed_apartment` — после первого клона **или** stage_4 + cost |
| API свиданий | `dating_api.gd` — park / cinema / arcade beats; auto occupancy mark |
| Телефон | `phone_ui.gd` — дом / кафе / парк / ресторан / кино / аркада / тематическая квартира |
| Agency board | `agency_board_ui.gd` — upcoming + clone slots + occupancy conflicts + apt assignment/buy |

---

## Home vs cafe vs park vs restaurant vs cinema vs arcade

**Home** — prep стола, sit/wait, без doorbell.

**Cafe (Pass 1)** — бронь → `sit_cafe`; ~30$; no prep.

**Park (Pass 2)** — `park_leisure`; 4 beats + optional rain→restaurant handoff.

**Restaurant** — ~90$; park unlock / venue.

**Cinema (Pass 3)** — ~45$; leisure / stage_3; `sit_cinema`.

**Arcade (Pass 3)** — ~25$; Pair Overload minigame.

**Themed apartments (Pass 5)** — home-like prep dates; unlock via agency board / elevator buy; travel via elevator.

---

## City Hub Pass 5 — Clone / date-house infrastructure

| Фича | Детали |
|------|--------|
| Lab | Home-cluster room `lab` (все стадии); basement interact + elevator; mounts `Clone_Lab_Base.tscn` + cold OmniLight; `create_clone` → ClonesAPI |
| Capacity | `DateSchedule.place_occupancy`; board conflict flags; toast on book if slot taken; autos mark live bucket `minutes=-1` |
| Themed apts | `apt_cozy` / `apt_modern` / `apt_creative` — greybox furniture colors; buy 200/350/280$; bookable as date places |
| Elevator | `ElevatorUI`: destinations main apt / lab / themed; direct spawn (no corridor); wrong-girl incident when clone date active |
| Agency | Board lists occupancy leads + apartment assignment (player/clone) + buy buttons |

### Playable routes

1. Apartment → «Подвал / лаборатория» or Elevator → Lab → create_clone.  
2. Elevator → buy themed apt (stage_4 or after clone) → travel into themed unit.  
3. Phone book themed apt (when unlocked) / Agency board assign lead.  
4. Book place while clone auto occupies same place → toast + board conflict.

---

## City Hub Pass 4 — Popularity / agency row

| Фича | Детали |
|------|--------|
| District | `CityDistricts.AGENCY_ROW` |
| Photo / Barber / Agency office | overlays as Pass 4 |

---

## City Hub Pass 3 — Leisure

Gym / Bookstore / Cinema / Arcade + LeisureStrip.

---

## City Hub Pass 1–2

Cafe, shops, park, restaurant.

---

## Мир Stage 1 (факт)

| Факт | Детали |
|------|--------|
| Boot | `boot.tscn` → New Game → `main.tscn`; `ComplexWorld` starts `home` / `_home_zone=apartment` with player FPS camera |
| Start load | Apartment + neighbor only (lab / themed apts load exclusively via basement / elevator `travel_to`) |
| Cafe / Park / Leisure / Agency markers | city visual (enter via «На улицу») |
| Lab / Elevator | exclusive home zones via `travel_to` (not co-spawned at boot) |
| Themed apts | unlockable home zones via elevator |
| Art cameras | Mounted slice TechCameras are forced off so they never steal FPS |}

---

## Ключевые файлы

| Область | Файлы |
|---------|--------|
| Dating | `dating_api.gd`, `date_schedule.gd`, `date_places.gd` |
| City / home hub | `city_api.gd`, `complex_world.gd` |
| Interact | `interaction_router.gd` |
| UI | `phone_ui.gd`, `agency_board_ui.gd`, `elevator_ui.gd`, photo/barber/gym |
| Lab art | `scenes/art/lab/Clone_Lab_Base.tscn` |

---

## Remaining gaps

1. Barber visual on Hero mesh (tags only)  
2. Full multi-booking calendar (still one player booking + autos)  
3. Themed apt art beyond greybox props  
4. Manual visual QA with runtime attach for elevator/lab
