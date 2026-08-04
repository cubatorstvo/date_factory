# DATE FACTORY — Implementation State

**Обновлено:** 2026-08-04  
**Сессия:** Boot → apartment FPS (no lab TechCamera overview at start)

---

## Текущее состояние проекта

Этапы **0–16 VERIFIED**. Трек влияния черт **T0–T8 VERIFIED**.  
Dating overhaul Stage 1 — **в коде**.  
**City Hub Pass 1–4** — shipped.  
**City Hub Pass 5** — shipped in code (lab + occupancy + themed apts + elevator + agency assignment).  
**Boot:** New Game lands in apartment FPS; lab/themed zones load only via `travel_to` (art TechCameras disabled on mount).

Подробности: [DATING_AND_WORLD.md](DATING_AND_WORLD.md).  
Итоговый отчёт: [CITY_HUB_EXPANSION_REPORT.md](CITY_HUB_EXPANSION_REPORT.md).

### Готово (City Hub Pass 5)

- Home-cluster `lab` (Clone_Lab_Base + cold light) via basement / elevator; `create_clone` → ClonesAPI
- `DateSchedule.place_occupancy` + toast on conflict; AgencyBoard conflict rows
- Themed apartments `apt_cozy` / `apt_modern` / `apt_creative` (buy after clone or stage_4)
- `ElevatorUI` destinations + wrong-girl incident (wait vs ride)
- Agency board apartment assignment (player/clone lead) + buy buttons
- Docs + check_errors on edited scripts

### Готово (City Hub Pass 4)

- Agency row + photo / barber / board

### Готово (City Hub Pass 1–3)

- Cafe / shops / park / restaurant / leisure strip

### Следующий gap

1. Barber mesh visuals / clone distinction  
2. True multi-booking calendar beyond single player slot + autos  
3. Themed apt art pass  
4. Manual visual QA with runtime attach

---

## Завершённые этапы

0–16 = VERIFIED  
T0–T8 = VERIFIED  
Dating overhaul must-fix = VERIFIED (GodotIQ playtest 2026-08-04)  
City Hub Pass 1 = IN CODE  
City Hub Pass 2 = IN CODE  
City Hub Pass 3 = IN CODE  
City Hub Pass 4 = IN CODE  
City Hub Pass 5 = IN CODE (check_errors on edited scripts; editor-smoke, not full FPS playtest)
