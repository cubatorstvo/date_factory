# 02 — Фактическое состояние текущего города

## Критическое уточнение сцен

| Сцена | Путь | Роль |
|-------|------|------|
| Запрошенная для анализа | `res://scenes/art/city/City_Street_Slice.tscn` | Art/kit testbed (17 узлов, BoxMesh) |
| Фактически играемый город | `res://scenes/world/city/city.tscn` | `CITY_SCENE`, compact hub (143 содержательных узла в экспорте) |

Ниже: **A)** Street Slice (как запрошено), **B)** Live city (обязателен для LD).  
Машиночитаемый дамп: `current_city_nodes.json` (live), `city_street_slice_nodes.json` (slice).

Координаты — **локальные** к корню сцены (до mount offset (−30,0,0) и scale ×1.5 в `ComplexWorld`).

Экспорт: 2026-08-05, headless instantiate + AABB union.

---

## A. `City_Street_Slice.tscn`

### Дерево содержательных узлов

```
City_Street_Slice (Node3D)
├── WorldEnvHint (DirectionalLight3D)
├── Floor (MeshInstance3D BoxMesh ~16×16)
├── Title (Label3D "City_Street_Slice")
├── Road (MeshInstance3D)
├── Sidewalk_N / Sidewalk_S
├── Facade_Home / Facade_Restaurant / Facade_ShopA / Facade_ShopB
├── Prop_Lamp / Prop_Bench
├── KitAnchors (Node3D, пустой)
├── Spawn (Marker3D @ (0, 0.1, 4))
├── TechCamera (Camera3D, current)
├── TechSun (DirectionalLight3D)
└── TechEnv (WorldEnvironment)
```

- **Территория (AABB):** ≈ X 20.5 × Z 20.3 × Y 12.5  
- **Spawn:** `(0, 0.1, 4)`  
- **Interactables / district gates / megakit instances:** нет  
- **Назначение:** PACK_001 kit validation (`docs/ASSET_IMPORT_MANIFEST.md` §8.2, `WORLD_POI_AUDIT.md`)  
- **Скриншоты:** `screenshots/current/slice_01_topdown.png`, `slice_02_spawn.png`

Это **не** текущий playable layout.

---

## B. Live `city.tscn` (играемый город)

### Размеры занятой территории

Из `current_city_nodes.json`:

| | Min | Max | Size |
|--|-----|-----|------|
| X | −34.23 | 31.5 | **65.73** |
| Y | −0.64 | 28.25 | 28.89 (вкл. OverviewCamera) |
| Z | −21.03 | 26.03 | **47.06** |

Практический walkable footprint по Architecture/edges: примерно X −23…+21, Z −9.5…+14.5.

### Точка появления игрока

| Marker | Local position |
|--------|----------------|
| `Markers/HomeEntrance` | `(14.2, 0, 1.5)` |
| `Markers/PlayerSpawn` | то же |
| `Markers/ApartmentReturn` | то же |

При mount: `CityVisual` @ (−30,0,0), root scale ×1.5 → world spawn смещается (`complex_world.gd`).

### Существующий маршрут игрока

По `CITY_MASTERPLAN.md` + markers:

1. **Home** `(14.2, 0, 1.5)` → commercial L-street  
2. **Cafe** `CafeEntrance (10.5, 0, −4.35)` / shops на positive-X strip  
3. **Central pocket** около `(1, 0, 0.5)` / StreetMid `(6, 0, 0.8)`  
4. **Park loop** через ParkGate `(0.5, 0, 3.4)` → picnic `(−2, 0, 8)` → restaurant `(−8, 0, 8)`  
5. **Leisure** gym/cinema/arcade около x≈−6…−12, z≈−5…+3  
6. **Agency lane** photo/barber/agency/bus x≈−15…−21  

Скриншоты маршрута: `03_topdown_route.png`, `05_route_01.png`…`05_route_13.png`.

### Контейнеры верхнего уровня

```
City
├── Architecture   — ground pads, roads, paths, edges, planters, bollards, PerimeterCollision
├── Buildings      — HomeFacade, CafeTwoHearts, BookstoreLeisure, EdgeBld*
├── POIs           — 19 prefab instances (shops, amenities, services)
├── Decor          — CentralPocket, ParkGate, AgencyGate, ZoneLabels
├── Markers        — spawn + POI/district markers
├── Districts      — ParkLeisure, LeisureStrip, AgencyRow
├── WorldEnvironment
└── NightKey (DirectionalLight3D)
```

### Здания и архитектура

**Authored CSG facades**

| Node | Position (approx) | Примечание |
|------|-------------------|------------|
| `Buildings/HomeFacade` | `(18, 0, 1.5)` | дверь домой, Label3D, Omni halo |
| `Buildings/CafeTwoHearts` | `(10.5, 0, −6.2)` | кафе, вывеска |
| `Buildings/BookstoreLeisure` | `(−3.5, 0, −4)` | leisure bookstore shell |

**Megakit edge fillers:** `EdgeBldNorthA/B`, `EdgeBldSouthA/B`, `EdgeBldWestA` → `Building_Small_1.gltf`.

**Roads / pads (CSG, use_collision часто false на visual pads):**  
`RoadCommercialEW`, `RoadCafeS`, `RoadAgency`, park paths, `CentralPaving`, `LeisurePaving`, `AgencyLanePad`, `ResidentialCourt`, `ParkGrass`, `Pond`, sidewalks, edge masses.

**Ограждения / коллизии:**  
`Architecture/PerimeterCollision` — WallEast/West/North/South + `FloorCollider` (StaticBody3D).  
Gates: `Decor/ParkGate`, `Decor/AgencyGate` (StaticBody + Barrier CSG + SoonLabel).

### Доступные / недоступные помещения

| Тип | Факт |
|-----|------|
| Уличные фасады POI | Визуально снаружи; интеракции — Area3D / overlays |
| Внутренности shops/cinema/gym как walkable rooms в city.tscn | **Нет** — UI overlays / `date_stage` |
| За gated districts до unlock | Физический barrier + inspect UI |
| Lab / themed apts | Не в city scene |

### Интерактивные объекты (runtime)

Сцена сама **не** содержит скриптовых Interactable на корне; `city_builder.gd` + `complex_world.gd` спавнят Area3D с `action_id` при mount. Prefab roots содержат якоря.

Ключевые action_ids:  
`go_home`, `sit_cafe`, `sit_park`, `sit_restaurant`, `sit_cinema`, `sit_arcade`,  
`open_flower_shop`, `open_jewelry_shop`, `open_gift_shop`, `open_clothing_shop`, `open_homeware_shop`, `open_bookstore`,  
`open_arcade`, `open_photo_studio`, `open_barber`, `open_agency_board`, `inspect_district_gate`,  
`city_rest`, `city_buy_gift`, `city_cafe_job`, `city_cafe_scroll`, `city_coffee`, `city_workout`, `city_gym_pass`,  
`city_park_fun`, `city_bar_drink`, `city_karaoke`, `city_bus_info`, `talk_girl`.

### Точки перехода

| Переход | Механика |
|---------|----------|
| City → Home | Interact home door → `go_home` |
| Home → City | Apt exit → `go_outside` → spawn `HomeEntrance` |
| District unlock | ParkGate / AgencyGate + `CityAPI` flags |

Отдельных `change_scene` на другие city.tscn нет — exclusive mount в ComplexWorld.

### Коллизии и навигация

- Perimeter walls + floor collider — да.  
- Building/POI prefabs — имеют StaticBody в prefab.  
- Многие CSG pads (`GroundPad` и дороги) в экспорте `has_collision=false` (visual); ходьба опирается на FloorCollider / prefab colliders.  
- **NavigationRegion3D отсутствует.**

### Освещение / Environment

- `WorldEnvironment` + `NightKey` на сцене.  
- Local Omni: `HomeHalo`, `CafeHalo`.  
- На mount ComplexWorld: city WE cleared, city DirectionalLights hidden; authority у complex environment (`WORLD_POI_AUDIT.md`).

### POI и фактические функции

| POI node | Prefab | Функция (логика) |
|----------|--------|------------------|
| FlowerShop … HomewareShop | prefabs | shop overlays |
| InternetCafe | prefab | cafe job/scroll/coffee amenities |
| MainBench / ParkBench | prefab | `city_rest` / sit |
| DuckFeeding | prefab | `city_park_fun` |
| ParkRestaurant | prefab | restaurant date sit |
| GymFacade | prefab | gym UI / pass |
| CinemaFacade / ArcadeFacade | prefab | dates + arcade minigame |
| KaraokeStand / BarFacade | prefab | karaoke / bar drink |
| PhotoStudio / BarberShop / AgencyOffice | prefab | Pass 4 overlays |
| BusStopCandy | prefab | bus info / candy |
| CafeTwoHearts (Buildings) | CSG | cafe date entrance |
| HomeFacade | CSG | return home |

### Очевидные проблемы (наблюдение, без исправлений)

Зафиксировано по дампу/скриншотам/аудитам; **не чинилось**:

1. **Двойная сцена-путаница:** Street Slice ≠ live city — риск неправильного редизайна.  
2. **CSG + редкий megakit:** большинство масс — greybox CSG; kit buildings почти не использованы как фасады POI.  
3. **Плотность commercial/leisure/agency кластеров** на коротких отрезках (см. `08_dense_*.png`).  
4. **Пустоты окраин** vs плотный центр (east court / west bus).  
5. **FocusProxy boxes** вместо outline на реальных meshes.  
6. **Hardcoded shop interacts** vs marker positions — возможный drift (`city_compact_layout_capture.md`).  
7. **Amenity visuals** могут быть скрыты `_hide_generated_visuals`.  
8. **Lighting на mount** не совпадает с target masterplan (WE stripped).  
9. **Нет walkable interiors** при наличии «дверных» фасадов — входы визуально обещают комнату.  
10. **AABB planters** в экспорте раздуты (gltf scale) — проверять масштаб Prop_Planter в редакторе.

---

## Полный перечень nodes

См. `current_city_nodes.json` / `city_street_slice_nodes.json`:  
NodePath, type, source, global transform, AABB, groups, metadata, collision/interaction flags, parent container.
