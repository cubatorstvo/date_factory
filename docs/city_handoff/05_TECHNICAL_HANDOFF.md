# 05 — Технический пакет для последующей перестройки

Только факты. Перестройка города **не выполнялась** в этом пакете.

---

## Какие файлы разрешено изменять при перестройке города

**Основной writable scope (один writer):**

1. `scenes/world/city/city.tscn` — live layout  
2. `scenes/art/city/prefabs/*.tscn` — POI roots (если двигаются вместе с interact/collision/outline anchors)  
3. Опционально новые authored props под `scenes/art/city/`  

**Только при смене контрактов (осторожно):**

- `scenes/world/complex_world.gd` — mount, marker resolve, FocusProxy, hide visuals  
- `scenes/world/city_builder.gd` — hardcoded interact positions  
- `modules/interaction/interaction_router.gd` — action routing  
- `modules/city/city_api.gd` / `city_districts.gd` — unlock flags  

**Не трогать без отдельной задачи:** dating/save/facility/clone pipelines, apartment art, lab art.

`City_Street_Slice.tscn` — kit testbed; **не** live mount. Менять его не обязательно для playable city.

---

## Какие системы нельзя ломать

| Система | Почему |
|---------|--------|
| `ComplexWorld.travel_to` exclusive home/city | Основной hub loop |
| Marker names из `validate_compact_city.gd` | Автотесты / spawn |
| District IDs `main_street` / `park_leisure` / `agency_row` | Save flags + DatePlaces unlock |
| action_ids interact | InteractionRouter + quests |
| Player instance lifetime | Игрок не пересоздаётся при входе в город |
| Save key city module | `autoload/game.gd` |
| Prefab «move root moves all interact structure» | `CITY_MASTERPLAN.md` |

---

## NodePath / groups / metadata / signals

### Required markers (`tools/validate_compact_city.gd`)

```
Markers/HomeEntrance
Markers/PlayerSpawn
Markers/ParkPicnicSpot
Markers/ParkRestaurantEntrance
Markers/GymEntrance
Markers/BookstoreEntrance
Markers/CinemaEntrance
Markers/ArcadeEntrance
Markers/PhotoStudioEntrance
Markers/BarberEntrance
Markers/AgencyOfficeEntrance
```

### Required nodes

```
Decor/ParkGate
Decor/AgencyGate
Decor/CentralPocket
POIs/FlowerShop … (см. validate list)
Architecture/PerimeterCollision/FloorCollider
Buildings/CafeTwoHearts
Buildings/HomeFacade
```

### Groups

| Group | Где |
|-------|-----|
| `world_root` | ComplexWorld `_ready` |
| `player` | `player.gd` |
| `ambient_machine` | machine interacts |
| UI groups | `photo_studio_ui`, `barber_ui`, `agency_board_ui`, `district_gate_ui`, … (`ui_escape.gd`) |

### Metadata / payload keys

- Gate: `gate_interact`  
- Payload: `art_backed`, `girl_id`, `district_id`, `venue_id`, `gift_id`, `bonus`, `dest`

### Signals

- `CityAPI.city_changed`  
- `EventBus.toast` / `notify` / `stage_changed`

---

## Как создаётся игрок

- Инстанс один раз в `scenes/boot/main.tscn` → `res://scenes/player/player.tscn`  
- При `travel_to(city)` игрок **не** recreate: `_rebuild()` монтирует city, `_place_player_at_spawn(HomeEntrance)` двигает существующий `CharacterBody3D`  
- `_ensure_player_camera` делает `Head/Camera3D` current  
- Art TechCameras на mounted slice принудительно выключаются

---

## Как работают переходы

1. Interactable с `action_id` (`go_outside` / `go_home` / …)  
2. `InteractionRouter.route` → `world.travel_to(location_id, spawn_marker)`  
3. `TransitionOverlay.run_blackout`  
4. Rebuild exclusive zone; place at marker  
5. `Sfx.set_zone`

City mount specifics (`complex_world.gd`):

- `CITY_SCENE = res://scenes/world/city/city.tscn`  
- Mount as `CityVisual` at `(-30, 0, 0)`  
- `city_root.scale = Vector3.ONE * 1.5`  
- `_hide_generated_visuals` после `CityBuilder.build`

---

## Интеракции и outline

1. `CityBuilder.build` + `_build_city` создают `Interactable` Area3D  
2. Player focus → screen-space outline (`shaders/interact_outline.gdshader` via `interactable.gd`)  
3. City art-backed POIs: `_attach_focus_proxy` — прозрачный `FocusProxy` BoxMesh `(0.9,1.7,0.9)`  
4. Квартира использует `bind_outline_root` на реальных meshes — **другой** паттерн  
5. Greybox amenity meshes из builder могут быть hidden; Area3D остаются

---

## Как проверять город в обычном игровом запуске

1. Boot → New Game / Load → `main.tscn`  
2. В квартире подойти к выходу → «На улицу» (`go_outside`)  
3. Появиться у HomeEntrance; проверить sightline к кафе  
4. Пройти commercial → central → ParkGate (inspect / unlock) → park loop → leisure → AgencyGate → agency lane → bus  
5. Вернуться `go_home`  
6. Проверить shop/date overlays без ожидания walkable interiors

Headless contract:

```text
godot --headless --path . -s res://tools/validate_compact_city.gd
```

Release suites: `tests/release/suites/full_progression_suite.gd`, `smoke_suite.gd`.

---

## Обязательные проверки после перестройки

1. `validate_compact_city.gd` — PASS  
2. Все REQUIRED_MARKERS существуют и в разумных зонах (home east, agency west)  
3. `go_outside` / `go_home` round-trip  
4. ParkGate / AgencyGate colliders + unlock copy  
5. Каждый POI action из Pass 1–4 открывает ожидаемый UI (не silent fail)  
6. Нет NavigationRegion regress (если не добавляли осознанно)  
7. Ручной visual: нет black void на edges, readable route, FOV player camera  
8. Save/load с unlocked districts  

Visual PASS объявляет только человек.

---

## Что можно генерировать автоматически

| Можно | Нельзя без ручной проверки |
|-------|----------------------------|
| Road/sidewalk grids из megakit tiles | POI root placement (контракты markers) |
| Edge filler buildings / vegetation scatter | Gate positions relative to unlock UX |
| Perimeter collision boxes | Interact Area3D offsets vs facades |
| Top-down capture (`capture_compact_city_topdown.gd`) | Lighting mood / sign readability |
| Prefab instances from index | Date sit anchors / animation marks |

Существующие builders: `tools/build_compact_city.gd`, `tools/build_city_poi_prefabs.gd`.

---

## Что расставлено вручную

- Compact zone CSG pads и authored Home/Cafe/Bookstore shells  
- Marker positions  
- Gate barriers + labels  
- CentralPocket fountain/planter composition  
- POI prefab transforms в `city.tscn`  
- Edge Building_Small_1 instances  

---

## Как сделать контейнер `GeneratedCity` без поломки ручных/системных узлов

Рекомендуемый контракт (предложение для будущего рефактора; **не внедрено**):

```
City
├── Systems          # Markers, Districts, gates, FloorCollider — DO NOT auto-wipe
├── HandAuthored     # HomeFacade, CafeTwoHearts, CentralPocket, unique landmarks
├── GeneratedCity    # roads, filler buildings, sidewalks, vegetation — safe regenerate
└── POIs             # prefab roots; move as wholes
```

Правила:

1. Генератор пишет **только** в `GeneratedCity` (clear children → rebuild).  
2. Никогда не удалять/переименовывать `Markers/*`, `Decor/ParkGate`, `Decor/AgencyGate`, required POI names.  
3. После генерации прогонять `validate_compact_city.gd`.  
4. Interact spawn остаётся в коде; либо перевести hardcodes на markers до массовой генерации.  
5. Сохранять `Architecture/PerimeterCollision/FloorCollider` или эквивалент walkable floor.  
6. Не класть Interactable внутрь генерируемых filler-зданий без якоря в Systems/POIs.

---

## Копии файлов в пакете

См. `copies/` — текстовые/сценовые city-related файлы (`.gd`, `.tscn`, `.md`, `.json`, shader).  
Тяжёлые meshes/textures **не** копировались — пути в `03_CITY_ASSET_CATALOG.md` / `city_asset_catalog.json`.
