# 01 — Контекст игры и назначение города

Пакет передачи для внешнего level designer. Только подтверждённые факты с источниками.  
**Важно о сценах:** запрошенная для анализа `City_Street_Slice.tscn` — art/kit testbed.  
**Фактически играемый город** — `scenes/world/city/city.tscn` (`ComplexWorld.CITY_SCENE`).

---

## Основной игровой цикл

| Утверждение | Источник |
|-------------|----------|
| Жанр: одиночная 3D FPS-инкременталка: ходить, готовить, встречаться, масштабировать инфраструктуру | `docs/PITCH.md`, `docs/PROJECT_CONCEPT.md` |
| Петля: заработок → подготовка → бронь места/времени (телефон) → свидание → расширение комплекса → позже клоны/автоматизация | `docs/03_PROGRESSION.md`, `docs/DATING_AND_WORLD.md` |
| Игровые часы: `TimeAPI` (~0.5 игровой минуты / реал-сек), пауза на активном свидании | `docs/DATING_AND_WORLD.md`, `modules/time/time_api.gd` |
| Свидания бронируются через телефон; уличные места — sit-wait без полного интерьера магазина | `docs/DATING_AND_WORLD.md`, `modules/dating/date_schedule.gd`, `scenes/ui/phone_ui.gd` |

---

## Место города в прогрессии

Арка стадий (дизайн): квартира → город/свидания → операционный штаб/логистика → клоны («Второй Я») → фабрика свиданий → корпорация.

| Стадия | Дизайн | Роль города в коде |
|--------|--------|-------------------|
| `stage_1` | Одинокая квартира → первое свидание | Город открыт (`main_street`); квест `s1_city` | 
| `stage_2` | Несколько отношений / время | Разблокировка `park_leisure` |
| `stage_3` | Операционный штаб | Разблокировка `agency_row`; штаб/агентство — в home-кластере |
| `stage_4` | Клоны | Лаборатория через лифт/подвал **дома**, не street travel |
| `stage_5`–`6` | Фабрика / корпорация | Home facility / орбита; не отдельная city-сцена |

Источники: `docs/03_PROGRESSION.md`, `docs/PROJECT_CONCEPT.md` («Город — источник новых номеров…»), `docs/DATING_AND_WORLD.md`, `modules/city/city_districts.gd`, `modules/city/city_api.gd`, `scenes/world/complex_world.gd`.

Город — **постоянный outdoor hub** с gated districts, а не отдельная стадия-сцена.

---

## Что игрок регулярно делает в городе

| Действие | Статус | Источник |
|----------|--------|----------|
| Выйти из квартиры на улицу / вернуться домой | **IMPLEMENTED** | `interaction_router.gd` (`go_outside` / `go_home`), `complex_world.gd` `travel_to` |
| Говорить с city/unique girls | **IMPLEMENTED** | `talk_girl`, `CityAPI` / `girls_api` |
| Бронь cafe / park / restaurant / cinema / arcade → sit-wait | **IMPLEMENTED** | `date_places.gd`, `dating_api.gd`, `DATING_AND_WORLD.md` |
| Магазины (flower/jewelry/gift/clothing/homeware/bookstore) | **IMPLEMENTED** (overlay UI) | `CITY_HUB_EXPANSION_REPORT.md`, shop action_ids |
| Gym / photo / barber / agency board | **IMPLEMENTED** | Pass 3–4, `CITY_HUB_EXPANSION_REPORT.md` |
| District gate inspect UI | **IMPLEMENTED** | `inspect_district_gate`, `DistrictGateUI` |
| Уличные amenities (bench, ducks, bar, karaoke, bus…) | **LOGIC IMPLEMENTED**; часть visual скрыта builder’ом | `city_builder.gd`, `_hide_generated_visuals` в `complex_world.gd`, `WORLD_POI_AUDIT.md` |
| Полноценные walkable interiors магазинов/ресторана как отдельные city rooms | **DOCS / цель**, не street interiors | `DATING_AND_WORLD.md` (dates → overlays / `date_stage`) |
| Open-world NavigationRegion | **NOT** | `WORLD_POI_AUDIT.md`, research handoff |

---

## Системы, требующие городских локаций

| Система | Что требует | Источник |
|---------|-------------|----------|
| Girls | City roster / talk / worthiness; kind `city` | `modules/city/city_api.gd`, `modules/girls/girls_api.gd` |
| Dates | cafe/park/restaurant/cinema/arcade при unlock районов | `modules/dating/date_places.gd` |
| Shops / inventory | Подарки, homeware, clothing и т.д. через shop overlays | `CITY_HUB_EXPANSION_REPORT.md` |
| Quests | `s1_city`; shop actions через `quests_api.can_do` | `modules/quests/quests_api.gd` |
| Content packs | маршруты `city_east` / `city_west` | `core/content_packs.gd` |
| Agency / photo / barber | район `agency_row` | `city_districts.gd`, Pass 4 |
| Themed apts / lab | **не** street-сцены; home zones через elevator | `DATING_AND_WORLD.md`, `complex_world.gd` |

---

## Вход в город и возврат

| Маршрут | action_id | Вызов | Spawn |
|---------|-----------|-------|-------|
| Квартира ExitDoor → город | `go_outside` | `world.travel_to(&"city", &"HomeEntrance")` | `Markers/HomeEntrance` |
| Дверь дома в городе → квартира | `go_home` | `travel_to(&"home", &"PlayerSpawn")` | apt `Markers/PlayerSpawn` |
| Apt → lab | `go_lab` / elevator | `travel_to(&"lab", …)` | home exclusive zone |
| Neighbor | `go_neighbor` | teleport в home tree | не city |

Источники: `modules/interaction/interaction_router.gd`, `scenes/world/complex_world.gd` (`travel_to`, `_resolve_spawn_position`).  
Оверлей: `TransitionOverlay.run_blackout`. SFX zone: `street` / `apartment` (`core/sfx.gd`).  
Масштаб города при mount: `CITY_WORLD_SCALE = 1.5`; `CityVisual` offset `(-30, 0, 0)`.

`travel_to` destinations: `city` | `home` | `apartment` | `lab` | `apt_cozy` | `apt_modern` | `apt_creative`.

---

## Implemented vs documentation-only

| Тема | Вердикт | Источник |
|------|---------|----------|
| Compact zones/loops + POI prefabs в `city.tscn` | **IMPLEMENTED** | `docs/release/CITY_MASTERPLAN.md`, `tools/validate_compact_city.gd` |
| City Hub Pass 1–5 activities | **IMPLEMENTED** (код/overlay) | `docs/CITY_HUB_EXPANSION_REPORT.md` |
| `City_Street_Slice` как live route | **NOT** — kit/validation | `docs/release/research/WORLD_POI_AUDIT.md`, `docs/release/SCENE_INVENTORY.md` |
| Marker-bound interacts вместо hardcodes | **PARTIAL** | `WORLD_POI_AUDIT.md`, `city_compact_layout_capture.md` |
| Outline на реальных facade meshes (как в квартире) | **TARGET**; city использует FocusProxy | `complex_world.gd` |
| Day/night от TimeAPI для city WE | **NOT** — city env/sun strip на mount | `WORLD_POI_AUDIT.md` |
| Prestige indoor wings / open-world scale | **DOCS** | `docs/08_FPS_AND_CRISES.md` |

---

## Целевая визуальная стилистика

| Токен / правило | Источник |
|-----------------|----------|
| «Stylized low-poly romantic corporate absurdism» | `docs/VISUAL_BIBLE.md` |
| Fantasy UI: «Romance Industry Luxury» | `docs/ART_DIRECTION.md` |
| Street palette: ground navy `#111821`, road violet-black `#242733`, destination pink `#FF4F9A` | `docs/VISUAL_BIBLE.md` |
| Street kit: PACK_001 Downtown MegaKit + project-authored road/lights/signs | `docs/VISUAL_BIBLE.md` |
| Compact neighborhood lighting: one WE, warm key, local shop lamps; park green / leisure amber / agency clean; no purple wash / black void | `docs/release/CITY_MASTERPLAN.md` |
| Edge concealment buildings/vegetation/bus terminus | `CITY_MASTERPLAN.md` |

---

## Текущие технические ограничения

| Ограничение | Источник |
|-------------|----------|
| Home **xor** city в дереве (взаимоисключающий mount) | `complex_world.gd`, `docs/vertical_slice/KNOWN_LIMITATIONS.md` |
| Стабильность имён markers / district IDs / action_ids | `tools/validate_compact_city.gd`, `city_districts.gd` |
| Нет `NavigationRegion3D`; NPC — waypoint arrays | research / `WORLD_POI_AUDIT.md` |
| `City_Street_Slice` / `street.tscn` ≠ `CITY_SCENE` | `complex_world.gd` L6, `SCENE_INVENTORY.md` |
| Godot 4.7; visual PASS только после ручной проверки | `.cursor/rules/date-factory-core.mdc` |
| Часть amenity meshes скрывается `_hide_generated_visuals` | `complex_world.gd`, `WORLD_POI_AUDIT.md` |
| На mount city WorldEnvironment cleared; DirectionalLights скрыты | `WORLD_POI_AUDIT.md` |

---

## Сцены для пакета

1. **Запрошенная:** `res://scenes/art/city/City_Street_Slice.tscn` — procedural BoxMesh kit slice, без megakit instances, без Interactable.  
2. **Live:** `res://scenes/world/city/city.tscn` — compact hub, markers, gates, POI prefabs.  
3. Prefabs: `res://scenes/art/city/prefabs/*.tscn`.  
4. Runtime host: `scenes/world/complex.tscn` + `complex_world.gd`.
