# Dating & World — текущее состояние кода

**Обновлено:** 2026-08-04  
Отражает реализацию после плейтест-переработки свиданий. Цель дизайна по-прежнему в [04_SYSTEMS.md](04_SYSTEMS.md) / [08_FPS_AND_CRISES.md](08_FPS_AND_CRISES.md); здесь — **что уже в коде**.

---

## Игровые часы

| Элемент | Путь / API |
|---------|------------|
| Часы | `modules/time/time_api.gd` (`TimeAPI`), создаётся через `Game.time` |
| Тик | ~0.5 игровой минуты / реал-сек при `Game.run_started`, пауза во время активного свидания |
| HUD | `scenes/ui/hud.gd` — день/часы + строка расписания + wait-UI за столом |
| Слоты брони | `TimeAPI.next_slots()` (шаг 30 мин, lead ≥45 мин) |

---

## Расписание и места

| Элемент | Путь / API |
|---------|------------|
| Каталог мест | `modules/dating/date_places.gd` — `home` (бесплатно, prep), `restaurant` (плата), homeware / еда / напитки / shop catalogs |
| Бронь | `modules/dating/date_schedule.gd` — place + day/minutes, cancel, reminders 30/5 мин; окно `ARRIVE_EARLY_MIN=10`, `NEUTRAL_LATE_MIN=10`, `WAIT_LEAVE_MIN=30` |
| API свиданий | `modules/dating/dating_api.gd` — `book_date`, `start_manual`, `give_date_gift`, `finish_manual`, 5 факторов результата |
| Телефон | `scenes/ui/phone_ui.gd` — выбор места → закрытие телефона → карточка слотов времени (EventsAPI); вкладка расписания + отмена |

Пунктуальность и prep (еда/напиток/посуда/outfit/подарок) входят в scoring; диалоги остаются основной осью (гипотезы не сняты).

---

## Home vs restaurant

**Home**

1. Бронь в телефоне → подготовка стола: fridge/drinks carry → table (`take_food` / `take_drink` / `prepare_and_start`).
2. **Без doorbell** — девушка не ждёт у двери. Стол + `player_seated` + окно `until ≤ 10` → auto-arrive / старт vignette.
3. Если рано (`until > 10`): sit → wait UI («Подождать до времени» / «Встать»); skip через `Game.time.skip_to_minutes`.
4. No-show при `until < -30`: toast, clear booking, bond ≈ `3 * bond_wrong`, scandal bump.
5. Vignette backdrop = apartment art (`date_stage.gd`); Hero sit deferred (`sit_enter` → `sit_idle`).

**Restaurant**

1. Бронь → к Two Hearts → `sit_restaurant` (без prep стола).
2. Оплата при старте; early wait → `skip_to_minutes` (как раньше).
3. Venue может быть locked на New Game до прогрессии facility.

---

## Подарки и магазины

- Полки подарков в квартире **не** часть flow; mesh `GiftShelf` скрывается runtime.
- Инвентарь подарков + shop UI: `scenes/ui/shop_ui.gd`, каталоги flower / jewelry / gift в `DatePlaces.shop_catalog`.
- Городские interacts: `open_flower_shop` / `open_jewelry_shop` / `open_gift_shop`.
- На свидании подарок **опционален**, один раз mid-date (`give_date_gift`); без подарка нет штрафа.
- После последней фазы UI остаётся открытым → **Завершить свидание** → панель пяти факторов.

---

## Пять факторов результата

После `finish_manual` панель в `date_ui.gd` показывает:

1. Пунктуальность  
2. Место / подготовка  
3. Одежда  
4. Подарок (или «без подарка (ок)»)  
5. Диалоги  

Toast с разбивкой остаётся вторичным.

---

## Мир Stage 1 (факт)

```
Main
└── ComplexWorld  (взаимоисключающий слот)
    ├── home → Rooms/ (apartment + neighbor + later indoor rooms), без города
    └── city → Props/CityDistrict + CityVisual (city.tscn @ -30), + Npcs
```

| Факт | Детали |
|------|--------|
| Сцены арта | `scenes/world/city/city.tscn` (корень `City`; mirror в `vertical_slice/street.tscn`), `vertical_slice/apartment.tscn` |
| Переходы | `ComplexWorld.travel_to(location_id, spawn_marker)` + TransitionOverlay; не `change_scene` Main |
| Старт | Локация `home`, спавн `Markers/PlayerSpawn` у двери |
| Фасад дома | Торец улицы: `PlayerHomeFacade` @ ~(21.6,0,0) rot Y=-90° (лицом на запад); `HomeEntrance` ~(18.5,0,-0.5); N/S fill `EastEndNorthFill` / `EastEndSouthFill`; interact «Мой дом» |
| Выход / вход | `go_outside` → city + HomeEntrance; `go_home` → home + PlayerSpawn |
| Сосед | Телепорт внутри home-кластера (`go_neighbor`) |
| DateStage | Отдельный vignette-pocket Y≈40; свой mount apartment/restaurant art |

Западные legacy markers `ApartmentReturn` / street `PlayerSpawn` не используются для входа домой.

---

## Ключевые файлы

| Область | Файлы |
|---------|--------|
| Время | `modules/time/time_api.gd` |
| Dating | `modules/dating/dating_api.gd`, `date_schedule.gd`, `date_places.gd` |
| Interact | `modules/interaction/interaction_router.gd` |
| Мир | `scenes/world/complex_world.gd` (`travel_to`), `city_builder.gd`, `scenes/world/city/city.tscn` |
| UI | `phone_ui.gd`, `date_ui.gd`, `shop_ui.gd`, `hud.gd` (wait panel) |
| Vignette | `scenes/dating/date_stage.gd` |
| Verify | `tools/verify_dating_overhaul.gd` |

---

## Что не трогаем без запроса

- Dialog / hypothesis pipeline (`GirlsAPI` observations)  
- Proxy girl POC (`docs/characters/*`, `assets/characters/girls/proxy_poc/`) как замена live DateGirl  
- Live date girl остаётся на `DateGirl_UAL`
